import { connect, getIn } from "formik";
import { useEffect } from "react";
import { FormHelperText, InputLabel } from "@material-ui/core";
import PropTypes from "prop-types";
import compact from "lodash/compact";

import { TALLY_FIELD_NAME } from "../constants";

import TallyFieldContainer from "./tally-field-container";
import css from "./styles.css";

const TallyField = ({ name, formik, field, helperText, InputLabelProps, label, ...rest }) => {
  const totalName = `${name}.total`;
  const tallyValues = compact(field.tally.map(option => getIn(formik.values, [name, option.id])));
  const errors = getIn(formik.errors, name);
  const renderError = errors && { error: true };

  useEffect(() => {
    if (field.autosum_total) {
      const total = tallyValues.reduce((acc, value) => acc + value, 0);

      formik.setFieldValue(totalName, total === 0 ? "" : total);
    }
  }, [JSON.stringify(tallyValues)]);

  return (
    <div className={css.tallyContainer}>
      <InputLabel htmlFor={name} {...InputLabelProps}>
        {label}
      </InputLabel>
      <div className={css.inputTally}>
        {field.tally.map(option => (
          <TallyFieldContainer name={`${name}.${option.id}`} option={option} {...rest} />
        ))}
        <TallyFieldContainer name={totalName} isTotal={field.autosum_total} {...rest} />
      </div>
      <FormHelperText {...renderError}>{errors || helperText}</FormHelperText>
    </div>
  );
};

TallyField.displayName = TALLY_FIELD_NAME;

TallyField.propTypes = {
  field: PropTypes.object,
  formik: PropTypes.object,
  formSection: PropTypes.object,
  helperText: PropTypes.string,
  InputLabelProps: PropTypes.object,
  label: PropTypes.string,
  name: PropTypes.string
};

export default connect(TallyField);
