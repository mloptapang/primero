# frozen_string_literal: true

require 'rails_helper'

# TODO: add i18n tests
describe Report do
  before :all do
    clean_data(PrimeroProgram, PrimeroModule, FormSection, Field, Child)
    @module = create :primero_module
  end

  it 'must have a name' do
    r = Report.new(
      record_type: 'case', unique_id: 'report-test', aggregate_by: %w[a b], module_id: @module.unique_id
    )
    expect(r.valid?).to be_falsey
    r.name = 'Test'
    expect(r.valid?).to be_truthy
  end

  it "must have an 'aggregate_by' value" do
    r = Report.new(
      name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id
    )
    expect(r.valid?).to be_falsey
    r.aggregate_by = %w[a b]
    expect(r.valid?).to be_truthy
  end

  it 'must have a record type associated with itself' do
    r = Report.new(
      name: 'Test', aggregate_by: %w[a b], module_id: @module.unique_id, unique_id: 'report-test'
    )
    expect(r.valid?).to be_falsey
    r.record_type = 'case'
    expect(r.valid?).to be_truthy
  end

  it "doesn't point to invalid modules" do
    r = Report.new(
      name: 'Test', aggregate_by: %w[a b], module_id: 'nosuchmodule', unique_id: 'report-test'
    )
    expect(r.valid?).to be_falsey
  end

  it 'lists reportable record types' do
    expect(Report.reportable_record_types).to include('case', 'incident', 'tracing_request', 'violation')
  end

  describe 'nested reports' do
    it 'lists reportsable nested record types' do
      expect(Report.reportable_record_types).to include(
        'reportable_follow_up', 'reportable_protection_concern', 'reportable_service'
      )
    end

    it 'has default follow up filters' do
      r = Report.new(record_type: 'reportable_follow_up', add_default_filters: true)
      r.apply_default_filters
      expect(r.filters).to include('attribute' => 'followup_date', 'constraint' => 'not_null')
    end

    it 'has default service filters' do
      r = Report.new(record_type: 'reportable_service', add_default_filters: true)
      r.apply_default_filters
      expect(r.filters).to include(
        { 'attribute' => 'service_type', 'value' => 'not_null' },
        'attribute' => 'service_appointment_date', 'constraint' => 'not_null'
      )
    end

    it 'has default protection concern filters' do
      r = Report.new(record_type: 'reportable_protection_concern', add_default_filters: true)
      r.apply_default_filters
      expect(r.filters).to include('attribute' => 'protection_concern_type', 'value' => 'not_null')
    end

    it 'generates a unique id' do
      r = Report.create!(
        name: 'Test', record_type: 'case', aggregate_by: %w[a b], module_id: @module.unique_id
      )
      expect(r.unique_id).to match(/^report-test-[0-9a-f]{7}$/)
    end
  end

  describe '#value_vector' do
    it 'will parse a Solr output to build a vector of pivot counts keyd by the pivot fields' do
      test_rsolr_output = {
        'pivot' => [
          {
            'value' => 'Somalia',
            'count' => 5,
            'pivot' => [
              { 'value' => 'male', 'count' => 3 },
              { 'value' => 'female', 'count' => 2 }
            ]
          },
          {
            'value' => 'Burundi',
            'count' => 7,
            'pivot' => [
              { 'value' => 'male', 'count' => 3 },
              { 'value' => 'female', 'count' => 4 }
            ]
          },
          {
            'value' => 'Kenya',
            'count' => 9,
            'pivot' => [
              { 'value' => 'male', 'count' => 5 },
              { 'value' => 'female', 'count' => 4 }
            ]
          }
        ]
      }

      r = Report.new
      result = r.value_vector([], test_rsolr_output)
      expect(result).to match_array(
        [
          [['', ''], nil],
          [['Somalia', ''], 5], [%w[Somalia male], 3], [%w[Somalia female], 2],
          [['Burundi', ''], 7], [%w[Burundi male], 3], [%w[Burundi female], 4],
          [['Kenya', ''], 9], [%w[Kenya male], 5], [%w[Kenya female], 4]
        ]
      )
    end
  end

  describe 'modules_present' do
    it 'will reject the empty module_id list' do
      r = Report.new record_type: 'case', aggregate_by: %w[a b], module_id: ''
      expect(r.valid?).to be_falsey
      expect(r.errors[:module_id][0]).to eq(I18n.t('errors.models.report.module_presence'))
    end

    it 'will reject the invalid module_id list' do
      r = Report.new record_type: 'case', aggregate_by: %w[a b], module_id: 'badmoduleid'
      expect(r.valid?).to be_falsey
      expect(r.errors[:module_id][0]).to eq(I18n.t('errors.models.report.module_syntax'))
    end

    it 'will accept the valid module_id list' do
      r = Report.new record_type: 'case', aggregate_by: %w[a b], module_id: 'primeromodule-cp'
      expect(r.modules_present).to be_nil
    end
  end

  describe 'values_as_json_hash' do
    it 'returns a hash with the values as nested keys' do
      report = Report.new
      report.stub(:values).and_return(%w[female country_1] => 5)
      values_as_hash = { 'female' => { 'country_1' => { '_total' => 5 } } }
      expect(report.values_as_json_hash).to eq(values_as_hash)
    end

    it 'returns a hash with the values as nested keys with 2 levels' do
      report = Report.new
      report.stub(:values).and_return(
        %w[female country_1] => 5,
        %w[female country_2] => 3,
        ['female', ''] => 8
      )
      values_as_hash = {
        'female' => {
          'country_1' => { '_total' => 5 },
          'country_2' => { '_total' => 3 },
          '_total' => 8
        }
      }
      expect(report.values_as_json_hash).to eq(values_as_hash)
    end

    it 'returns a hash with the values as nested keys with 3 levels' do
      report = Report.new
      report.stub(:values).and_return(
        %w[female country_1 city_1] => 2,
        %w[female country_1 city_2] => 2,
        %w[female country_2 city_1] => 3,
        %w[female country_2 city_2] => 2,
        ['female', 'country_1', ''] => 4,
        ['female', 'country_2', ''] => 5,
        ['female', '', ''] => 9,
        %w[male country_1 city_1] => 2,
        %w[male country_1 city_2] => 2,
        %w[male country_2 city_1] => 3,
        %w[male country_2 city_2] => 2,
        ['male', 'country_1', ''] => 4,
        ['male', 'country_2', ''] => 5,
        ['male', '', ''] => 9
      )
      values_as_hash = {
        'female' => {
          'country_1' => {
            'city_1' => { '_total' => 2 },
            'city_2' => { '_total' => 2 },
            '_total' => 4
          },
          'country_2' => {
            'city_1' => { '_total' => 3 },
            'city_2' => { '_total' => 2 },
            '_total' => 5
          },
          '_total' => 9
        },
        'male' => {
          'country_1' => {
            'city_1' => { '_total' => 2 },
            'city_2' => { '_total' => 2 },
            '_total' => 4
          },
          'country_2' => {
            'city_1' => { '_total' => 3 },
            'city_2' => { '_total' => 2 },
            '_total' => 5
          },
          '_total' => 9
        }
      }
      expect(report.values_as_json_hash).to eq(values_as_hash)
    end
  end

  describe 'is_graph' do
    context 'when is_graph is in params' do
      before do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             is_graph: true)
      end

      it 'has value for is_graph' do
        expect(@report.is_graph).to be_truthy
      end

      it 'has value for graph' do
        expect(@report.graph).to be_truthy
      end
    end

    context 'when graph is in params' do
      before do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             graph: true)
      end

      it 'has value for is_graph' do
        expect(@report.is_graph).to be_truthy
      end

      it 'has value for graph' do
        expect(@report.graph).to be_truthy
      end
    end

    context 'when is_graph is updated' do
      before :each do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             is_graph: false)
      end

      it 'updates is_graph' do
        expect(@report.is_graph).to be_falsey

        @report.update_properties(is_graph: true)
        expect(@report.is_graph).to be_truthy
      end

      it 'updates graph' do
        expect(@report.graph).to be_falsey

        @report.update_properties(is_graph: true)
        expect(@report.graph).to be_truthy
      end
    end

    context 'when graph is updated' do
      before :each do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             graph: false)
      end

      it 'updates is_graph' do
        expect(@report.is_graph).to be_falsey

        @report.update_properties(graph: true)
        expect(@report.is_graph).to be_truthy
      end

      it 'updates graph' do
        expect(@report.graph).to be_falsey

        @report.update_properties(graph: true)
        expect(@report.graph).to be_truthy
      end
    end
  end

  describe 'exclude_empty_rows', search: true do
    before :each do
      clean_data(FormSection, Field, Child, Report)

      SystemSettings.stub(:current).and_return(
        SystemSettings.new(
          primary_age_range: 'primero',
          age_ranges: {
            'primero' => [0..5, 6..11, 12..17, 18..AgeRange::MAX],
            'unhcr' => [0..4, 5..11, 12..17, 18..59, 60..AgeRange::MAX]
          }
        )
      )

      Child.create!(data: { sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { sex: 'male', module_id: @module.unique_id })

      Child.reindex
    end

    context 'when it is true' do
      before :each do
        @report = Report.new(
          name: 'Test',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: true,
          aggregate_by: ['sex'],
          disaggregate_by: []
        )
      end

      it 'should not return values with zero' do
        Child.where('data @> ?', { sex: 'male' }.to_json).each(&:remove_from_index!)

        @report.build_report

        expect(@report.values).to eq(['female'] => 3, [''] => nil)
      end
    end

    context 'when it is false' do
      before :each do
        @report = Report.new(
          name: 'Test',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: false,
          aggregate_by: ['sex'],
          disaggregate_by: []
        )
      end

      it 'should return values with zero' do
        Child.where('data @> ?', { sex: 'male' }.to_json).each(&:remove_from_index!)

        @report.build_report

        expect(@report.values).to eq(['female'] => 3, ['male'] => 0, [''] => nil)
      end
    end
  end

  describe 'filter_query', search: true do
    before :each do
      clean_data(FormSection, Field, Child, Report)

      SystemSettings.stub(:current).and_return(
        SystemSettings.new(
          primary_age_range: 'primero',
          age_ranges: {
            'primero' => [0..5, 6..11, 12..17, 18..AgeRange::MAX],
            'unhcr' => [0..4, 5..11, 12..17, 18..59, 60..AgeRange::MAX]
          }
        )
      )

      Child.create!(data: { status: 'closed', worklow: 'closed', sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { status: 'closed', worklow: 'closed', sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { status: 'closed', worklow: 'closed', sex: 'male', module_id: @module.unique_id })
      Child.reindex
      Sunspot.commit
    end

    context 'when it has filter' do
      before :each do
        @report = Report.new(
          name: 'Test',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: true,
          aggregate_by: ['sex'],
          disaggregate_by: [],
          filters: [
            {
              attribute: 'status',
              value: [
                'closed'
              ]
            }
          ]
        )
      end

      it 'should return 2 female and 1 male' do
        @report.build_report
        expect(@report.values).to eq(['female'] => 2, ['male'] => 1, [''] => nil)
      end
    end

    context 'when it has a filter with two values' do
      before :each do
        @report = Report.new(
          name: 'Test - filter with two values',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: true,
          aggregate_by: %w[sex status],
          disaggregate_by: [],
          filters: [
            {
              attribute: 'status',
              value: %w[open closed]
            }
          ]
        )
      end

      it 'should return 3 female and 1 male total' do
        @report.build_report
        expect(@report.values).to eq(
          {
            %w[female closed] => 2, %w[female open] => 1, ['female', ''] => 3,
            %w[male closed] => 1, ['male', ''] => 1, ['', ''] => nil
          }
        )
      end
    end
  end

  describe 'agency report scope', search: true do
    let(:agency) { Agency.create!(name: 'Test Agency', agency_code: 'TA1', services: ['Test type']) }
    let(:agency_with_space) do
      Agency.create!(name: 'Test Agency with Space', agency_code: 'TA TA', services: ['Test type'])
    end

    let(:case_worker) do
      user = User.new(user_name: 'case_worker', agency_id: agency.id)
      user.save(validate: false) && user
    end

    let(:service_provider) do
      user = User.new(
        user_name: 'service_provider', agency_id: agency_with_space.id)
      user.save(validate: false) && user
    end

    before(:each) do
      clean_data(User, Agency, Child, Report)
      child = Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id,
          services_section: [
            {
              unique_id: '1', service_type: 'alternative_care',
              service_implemented_day_time: Time.now,
              service_implementing_agency: 'AGENCY WITH SPACE',
              service_implementing_agency_individual: 'service_provider'
            }
          ],
          owned_by: case_worker.user_name,
          assigned_user_names: [service_provider.user_name]
        }
      )
      child.index_nested_reportables
      Child.reindex
      Sunspot.commit
    end

    let(:report) do
      Report.new(
        name: 'Services',
        record_type: 'reportable_service',
        module_id: @module.unique_id,
        aggregate_by: ['service_type'],
        disaggregate_by: ['service_implemented'],
        permission_filter: { 'attribute' => 'associated_user_agencies', 'value' => [agency_with_space.unique_id] }
      )
    end

    it 'can be seen by the agency scope even if the agency has blank spaces in it unique_id' do
      report.build_report
      expect(report.data[:values][%w[alternative_care implemented]]).to eq(1)
    end
  end

  describe 'user group report scope', search: true do
    let(:group_1) { UserGroup.create!(name: 'Test User Group 1') }
    let(:group_2) { UserGroup.create!(name: 'Test User Group 2') }

    let(:case_worker_1) do
      user = User.new(user_name: 'case_worker_1', user_groups: [group_1])
      user.save(validate: false) && user
    end

    let(:case_worker_2) do
      user = User.new(user_name: 'case_worker_2', user_groups: [group_1, group_2])
      user.save(validate: false) && user
    end

    let(:case_worker_3) do
      user = User.new(user_name: 'case_worker_3', user_groups: [group_2])
      user.save(validate: false) && user
    end

    let(:child_1) do
      Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'male', module_id: @module.unique_id,
          owned_by: case_worker_1.user_name
        }
      )
    end

    let(:child_2) do
      Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id,
          owned_by: case_worker_2.user_name
        }
      )
    end

    let(:child_3) do
      Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id,
          owned_by: case_worker_3.user_name
        }
      )
    end

    before(:each) do
      clean_data(User, UserGroup, Child, Report)
      child_1
      child_2
      child_3
      Child.reindex
      Sunspot.commit
    end

    let(:report) do
      Report.new(
        name: 'Report by Status and Sex',
        record_type: 'case',
        module_id: @module.unique_id,
        aggregate_by: ['status'],
        disaggregate_by: ['sex'],
        permission_filter: { 'attribute' => 'owned_by_groups', 'value' => [group_1.unique_id] }
      )
    end

    it 'can be seen by the group scope' do
      report.build_report
      expect(report.data[:values][%w[open male]]).to eq(1)
      expect(report.data[:values][%w[open female]]).to eq(1)
    end

    it 'can be seen by group if they also meet the filter' do
      report.filters = [{ 'attribute' => 'owned_by_groups', 'value' => [group_2.unique_id] }]
      report.build_report
      expect(report.data[:values][%w[open male]]).to eq(0)
      expect(report.data[:values][%w[open female]]).to eq(1)
    end
  end
end
