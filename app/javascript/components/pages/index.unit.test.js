import { expect } from "../../test";

import * as index from "./index";

describe("pages - index", () => {
  const indexValues = { ...index };

  it("should have known properties", () => {
    expect(indexValues).to.be.an("object");
    [
      "Admin",
      "AgenciesForm",
      "AgenciesList",
      "AuditLogs",
      "ContactInformation",
      "Dashboard",
      "default",
      "ExportList",
      "LookupsList",
      "NotAuthorized",
      "NotFound",
      "PotentialMatches",
      "Report",
      "Reports",
      "RolesForm",
      "RolesList",
      "Support",
      "TaskList",
      "UserGroupsForm",
      "UserGroupsList",
      "UsersForm",
      "UsersList"
    ].forEach(property => {
      expect(indexValues).to.have.property(property);
      delete indexValues[property];
    });
    expect(indexValues).to.be.empty;
  });
});
