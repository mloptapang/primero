import { useState } from "react";
import PropTypes from "prop-types";
import { Grid } from "@material-ui/core";
import VisibilityIcon from "@material-ui/icons/Visibility";
import CreateIcon from "@material-ui/icons/Create";
import { batch, useDispatch } from "react-redux";
import { push } from "connected-react-router";

import { READ_RECORDS, RESOURCES, WRITE_RECORDS } from "../../../../libs/permissions";
import { usePermissions } from "../../../user";
import { useI18n } from "../../../i18n";
import { NAME_DETAIL } from "../../constants";
import DisplayData from "../../../display-data";
import ActionButton from "../../../action-button";
import { ACTION_BUTTON_TYPES } from "../../../action-button/constants";
import { setSelectedForm } from "../../../record-form/action-creators";
import { setCaseIdForIncident } from "../../../records/action-creators";
import RedirectDialog from "../redirect-dialog";

import { EDIT, VIEW } from "./constants";

const Component = ({
  css,
  handleSubmit,
  incidentCaseId,
  incidentCaseIdDisplay,
  incidentDateInterview,
  incidentDate,
  incidentUniqueID,
  incidentType,
  mode,
  setFieldValue,
  recordType
}) => {
  const i18n = useI18n();
  const dispatch = useDispatch();
  const [redirectOpts, setRedirectOpts] = useState({});
  const canViewIncidents = usePermissions(RESOURCES.incidents, READ_RECORDS);
  const canEditIncidents = usePermissions(RESOURCES.incidents, WRITE_RECORDS);
  const incidentInterviewLabel = i18n.t("incidents.date_of_interview");
  const incidentDateLabel = i18n.t("incidents.date_of_incident");
  const incidentTypeLabel = i18n.t("incidents.type_violence");
  let incidentPath = null;

  const redirectIncident = path => {
    batch(() => {
      dispatch(setSelectedForm(null));
      dispatch(setCaseIdForIncident(incidentCaseId, incidentCaseIdDisplay));
      dispatch(push(path));
    });
  };

  const handleEvent = modeEvent => {
    incidentPath = `/${RESOURCES.incidents}/${incidentUniqueID}${modeEvent === VIEW ? "" : `/${EDIT}`}`;
    if (!mode.isShow) {
      setRedirectOpts({ open: true, incidentPath });
    } else {
      redirectIncident(incidentPath);
    }
  };

  const handleClickViewIncident = () => handleEvent(VIEW);
  const handleClickEditIncident = () => handleEvent(EDIT);

  const viewIncidentBtn = canViewIncidents && (
    <ActionButton
      icon={<VisibilityIcon />}
      text={i18n.t(`buttons.${VIEW}`)}
      type={ACTION_BUTTON_TYPES.default}
      outlined
      rest={{
        onClick: handleClickViewIncident
      }}
    />
  );
  const editIncidentBtn = canEditIncidents && (
    <ActionButton
      icon={<CreateIcon />}
      text={i18n.t(`buttons.${EDIT}`)}
      type={ACTION_BUTTON_TYPES.default}
      outlined
      rest={{
        onClick: handleClickEditIncident
      }}
    />
  );
  const renderDialog = redirectOpts.open && !mode.isShow && (
    <RedirectDialog
      setFieldValue={setFieldValue}
      handleSubmit={handleSubmit}
      mode={mode}
      recordType={recordType}
      setRedirectOpts={setRedirectOpts}
      {...redirectOpts}
    />
  );

  return (
    <>
      <Grid container spacing={2}>
        <Grid item md={9} xs={12}>
          <Grid item md={12} xs={12}>
            <div className={css.spaceGrid}>
              <DisplayData label={incidentInterviewLabel} value={incidentDateInterview} />
            </div>
          </Grid>
          <Grid item md={12} xs={12}>
            <div className={css.spaceGrid}>
              <DisplayData label={incidentDateLabel} value={incidentDate} />
            </div>
          </Grid>
          <Grid item md={12} xs={12}>
            <div className={css.spaceGrid}>
              <DisplayData label={incidentTypeLabel} value={incidentType} />
            </div>
          </Grid>
        </Grid>
        <Grid item md={3} xs={12}>
          <div className={css.buttonsActions}>
            {viewIncidentBtn}
            {editIncidentBtn}
            {renderDialog}
          </div>
        </Grid>
      </Grid>
    </>
  );
};

Component.displayName = NAME_DETAIL;

Component.propTypes = {
  css: PropTypes.object.isRequired,
  handleSubmit: PropTypes.func,
  incidentCaseId: PropTypes.string,
  incidentCaseIdDisplay: PropTypes.string,
  incidentDate: PropTypes.string,
  incidentDateInterview: PropTypes.string,
  incidentType: PropTypes.node,
  incidentUniqueID: PropTypes.string,
  mode: PropTypes.object,
  recordType: PropTypes.string,
  setFieldValue: PropTypes.func
};
export default Component;
