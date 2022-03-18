import { useEffect } from "react";
import PropTypes from "prop-types";
import { useDispatch } from "react-redux";
import { fromJS } from "immutable";
import { useParams } from "react-router-dom";
import isEmpty from "lodash/isEmpty";

import ActionDialog from "../../../action-dialog";
import Form from "../../../form";
import { clearExportedInsight, exportInsights } from "../../action-creators";
import { getInsightExport, getInsightFilters } from "../../selectors";
import { RECORD_TYPES } from "../../../../config";
import { useMemoizedSelector } from "../../../../libs";
import { EXPORT_FORMAT } from "../../../record-actions/exports/constants";

import { NAME, FORM_ID, EXPORTED_URL } from "./constants";
import { form } from "./form";

const Component = ({ close, i18n, open, pending, setPending }) => {
  const dispatch = useDispatch();
  const { id } = useParams();
  const dialogPending = typeof pending === "object" ? pending.get("pending") : pending;
  const insightFilters = useMemoizedSelector(state => getInsightFilters(state));
  const exportedInsight = useMemoizedSelector(state => getInsightExport(state));

  const onSubmit = data => {
    const params = insightFilters.merge(
      fromJS({
        ...data,
        export_type: EXPORT_FORMAT.EXCEL,
        id,
        record_type: RECORD_TYPES.incidents
      })
    );

    setPending(true);
    dispatch(exportInsights({ params, message: i18n.t("managed_reports.success_message") }));
  };

  useEffect(() => {
    if (exportedInsight.size > 0 && !isEmpty(exportedInsight.get(EXPORTED_URL))) {
      window.open(exportedInsight.get(EXPORTED_URL));
    }

    return () => {
      dispatch(clearExportedInsight());
    };
  }, [exportedInsight]);

  return (
    <ActionDialog
      open={open}
      confirmButtonProps={{
        form: FORM_ID,
        type: "submit"
      }}
      cancelHandler={close}
      dialogTitle={i18n.t("buttons.export")}
      confirmButtonLabel={i18n.t("buttons.export")}
      pending={dialogPending}
      omitCloseAfterSuccess
    >
      <Form useCancelPrompt formID={FORM_ID} mode="new" formSections={form(i18n)} onSubmit={onSubmit} submitAlways />
    </ActionDialog>
  );
};

Component.displayName = NAME;

Component.propTypes = {
  close: PropTypes.func,
  i18n: PropTypes.object,
  moduleID: PropTypes.string,
  open: PropTypes.bool,
  pending: PropTypes.bool,
  setPending: PropTypes.func
};

export default Component;
