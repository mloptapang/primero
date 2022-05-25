import { useState } from "react";
import PropTypes from "prop-types";
import { fromJS, List } from "immutable";

import { RECORD_TYPES } from "../../../config";
import { useI18n } from "../../i18n";
import ActionDialog from "../../action-dialog";
import { usePermissions, ACTIONS } from "../../permissions";
import { useMemoizedSelector } from "../../../libs";
import { getMiniFormFields } from "../../record-form";
import Form, { FORM_MODE_SHOW } from "../../form";

import viewModalForm from "./form";
import TransferRequest from "./transfer-request";
import { COMMON_FIELD_NAMES, FORM_ID, NAME } from "./constants";

const ViewModal = ({ close, openViewModal, currentRecord, recordType }) => {
  const i18n = useI18n();
  const [sendRequest, setSendRequest] = useState(false);

  const commonFieldNames = Object.values(COMMON_FIELD_NAMES);
  const miniFormFields = useMemoizedSelector(state =>
    getMiniFormFields(state, RECORD_TYPES[recordType], currentRecord?.get("module_id"), commonFieldNames, true)
  );

  const commonMiniFormFields = miniFormFields
    .filter(field => commonFieldNames.includes(field.name))
    .reduce((acc, elem) => acc.merge(fromJS({ [elem.name]: elem })), fromJS({}));

  const otherMiniFormFields = miniFormFields.filter(field => !commonFieldNames.includes(field.name));

  const canRequestTransfer = usePermissions(recordType, [ACTIONS.MANAGE, ACTIONS.REQUEST_TRANSFER]);

  const form = viewModalForm(i18n, commonMiniFormFields, otherMiniFormFields);

  const handleOk = () => {
    setSendRequest(true);
    close();
  };

  const caseId = `ID #${currentRecord && currentRecord.get("case_id_display")}`;

  const confirmButtonProps = {
    color: "primary",
    variant: "outlined",
    autoFocus: true
  };

  const sendRequestProps = {
    open: sendRequest,
    setOpen: setSendRequest,
    currentRecord,
    caseId
  };

  const initialValues = (currentRecord || fromJS({})).reduce(
    (acc, value, key) => ({ ...acc, [key]: value instanceof List ? [...value] : value }),
    {}
  );

  const onSubmit = () => {};

  return (
    <>
      <ActionDialog
        open={openViewModal}
        successHandler={handleOk}
        dialogTitle={caseId}
        confirmButtonLabel={i18n.t("buttons.request_transfer")}
        confirmButtonProps={confirmButtonProps}
        onClose={close}
        showSuccessButton={canRequestTransfer}
      >
        <Form
          formID={FORM_ID}
          onSubmit={onSubmit}
          useCancelPrompt
          mode={FORM_MODE_SHOW}
          formSections={form}
          initialValues={initialValues}
        />
      </ActionDialog>
      <TransferRequest {...sendRequestProps} />
    </>
  );
};

ViewModal.displayName = NAME;

ViewModal.propTypes = {
  close: PropTypes.func,
  currentRecord: PropTypes.object,
  openViewModal: PropTypes.bool,
  recordType: PropTypes.string.isRequired
};

export default ViewModal;
