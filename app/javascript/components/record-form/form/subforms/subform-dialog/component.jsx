import React from "react";
import PropTypes from "prop-types";
import {
  Box,
  IconButton,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle
} from "@material-ui/core";
import CloseIcon from "@material-ui/icons/Close";
import CheckIcon from "@material-ui/icons/Check";

import FormSectionField from "../../form-section-field";
import { SUBFORM_DIALOG } from "../constants";
import ServicesSubform from "../services-subform";
import SubformMenu from "../subform-menu";
import { serviceHasReferFields } from "../../utils";
import ActionButton from "../../../../action-button";
import { ACTION_BUTTON_TYPES } from "../../../../action-button/constants";

const Component = ({
  index,
  field,
  mode,
  open,
  setOpen,
  title,
  dialogIsNew,
  i18n,
  formik
}) => {
  const handleClose = () => {
    setOpen({ open: false, index: null });
  };

  const buttonDialogText = dialogIsNew ? "buttons.add" : "buttons.update";

  if (index !== null) {
    const actionButton =
      mode.isEdit || mode.isNew ? (
        <ActionButton
          icon={<CheckIcon />}
          text={i18n.t(buttonDialogText)}
          type={ACTION_BUTTON_TYPES.default}
          rest={{
            onClick: handleClose
          }}
        />
      ) : null;

    return (
      <Dialog open={open} maxWidth="sm" fullWidth>
        <DialogTitle disableTypography>
          <Box display="flex" alignItems="center">
            <Box flexGrow={1}>{title}</Box>
            <Box display="flex">
              {field.subform_section_id.unique_id === "services_section" &&
              mode.isShow &&
              serviceHasReferFields(formik.values.services_section[index]) ? (
                <SubformMenu
                  index={index}
                  values={formik.values.services_section}
                />
              ) : null}
              <IconButton onClick={handleClose}>
                <CloseIcon />
              </IconButton>
            </Box>
          </Box>
        </DialogTitle>
        <DialogContent>
          {field.subform_section_id.unique_id === "services_section" ? (
            <ServicesSubform
              field={field}
              index={index}
              mode={mode}
              formik={formik}
            />
          ) : (
            field.subform_section_id.fields.map(f => {
              const fieldProps = {
                name: `${field.name}[${index}].${f.name}`,
                field: f,
                mode,
                index,
                parentField: field
              };

              return (
                <Box my={3} key={f.name}>
                  <FormSectionField {...fieldProps} />
                </Box>
              );
            })
          )}
        </DialogContent>
        <DialogActions>{actionButton}</DialogActions>
      </Dialog>
    );
  }

  return null;
};

Component.displayName = SUBFORM_DIALOG;

Component.propTypes = {
  dialogIsNew: PropTypes.bool.isRequired,
  field: PropTypes.object.isRequired,
  formik: PropTypes.object.isRequired,
  i18n: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  mode: PropTypes.object.isRequired,
  open: PropTypes.bool.isRequired,
  setOpen: PropTypes.func.isRequired,
  title: PropTypes.string.isRequired
};

export default Component;
