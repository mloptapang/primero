import { namespaceActions } from "../../libs";

import NAMESPACE from "./namespace";

export default namespaceActions(NAMESPACE, [
  "DISABLE_NAVIGATION",
  "FETCH_ROLES",
  "FETCH_ROLES_FAILURE",
  "FETCH_ROLES_FINISHED",
  "FETCH_ROLES_STARTED",
  "FETCH_ROLES_SUCCESS",
  "FETCH_MANAGED_ROLES",
  "FETCH_MANAGED_ROLES_FAILURE",
  "FETCH_MANAGED_ROLES_FINISHED",
  "FETCH_MANAGED_ROLES_STARTED",
  "FETCH_MANAGED_ROLES_SUCCESS",
  "FETCH_SANDBOX_UI",
  "FETCH_SANDBOX_UI_FAILURE",
  "FETCH_SANDBOX_UI_FINISHED",
  "FETCH_SANDBOX_UI_STARTED",
  "FETCH_SANDBOX_UI_SUCCESS",
  "FETCH_SYSTEM_PERMISSIONS",
  "FETCH_SYSTEM_PERMISSIONS_FAILURE",
  "FETCH_SYSTEM_PERMISSIONS_FINISHED",
  "FETCH_SYSTEM_PERMISSIONS_STARTED",
  "FETCH_SYSTEM_PERMISSIONS_SUCCESS",
  "FETCH_SYSTEM_SETTINGS",
  "FETCH_SYSTEM_SETTINGS_SUCCESS",
  "FETCH_USER_GROUPS",
  "FETCH_USER_GROUPS_FAILURE",
  "FETCH_USER_GROUPS_FINISHED",
  "FETCH_USER_GROUPS_STARTED",
  "FETCH_USER_GROUPS_SUCCESS",
  "NETWORK_STATUS",
  "SET_USER_IDLE"
]);
