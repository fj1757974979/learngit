-- Generated By protoc-gen-lua Do not Edit
local protobuf = import("net/protobuf/protobuf.lua")
pb_table = {}

pb_table.LOGINMETHODID = protobuf.EnumDescriptor();
pb_table.LOGINMETHODID_SDK_LOGIN_ENUM = protobuf.EnumValueDescriptor();
pb_table.LOGINMETHODID_TOU_LOGIN_ENUM = protobuf.EnumValueDescriptor();
DEVICEINFO = protobuf.Descriptor();
pb_table.DEVICEINFO_PLATFORM_FIELD = protobuf.FieldDescriptor();
pb_table.DEVICEINFO_PHONE_MODEL_FIELD = protobuf.FieldDescriptor();
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD = protobuf.FieldDescriptor();
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD = protobuf.FieldDescriptor();
CLIENTINFO = protobuf.Descriptor();
pb_table.CLIENTINFO_VERSION_FIELD = protobuf.FieldDescriptor();
pb_table.CLIENTINFO_CHANNEL_FIELD = protobuf.FieldDescriptor();
pb_table.CLIENTINFO_IP_FIELD = protobuf.FieldDescriptor();
SDKAUTHREQUEST = protobuf.Descriptor();
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD = protobuf.FieldDescriptor();
pb_table.SDKAUTHREQUEST_TOKEN_FIELD = protobuf.FieldDescriptor();
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD = protobuf.FieldDescriptor();
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD = protobuf.FieldDescriptor();
pb_table.SDKAUTHREQUEST_CLIENT_FIELD = protobuf.FieldDescriptor();
pb_table.SDKAUTHREQUEST_DEVICE_FIELD = protobuf.FieldDescriptor();
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD = protobuf.FieldDescriptor();
TOUAUTHREQUEST = protobuf.Descriptor();
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD = protobuf.FieldDescriptor();
pb_table.TOUAUTHREQUEST_CLIENT_FIELD = protobuf.FieldDescriptor();
pb_table.TOUAUTHREQUEST_DEVICE_FIELD = protobuf.FieldDescriptor();
AUTHREPLY = protobuf.Descriptor();
pb_table.AUTHREPLY_ERRORCODE = protobuf.EnumDescriptor();
pb_table.AUTHREPLY_ERRORCODE_SUCCESS_ENUM = protobuf.EnumValueDescriptor();
pb_table.AUTHREPLY_ERRORCODE_AUTH_FAIL_ENUM = protobuf.EnumValueDescriptor();
pb_table.AUTHREPLY_ERRORCODE_VERSION_ERR_ENUM = protobuf.EnumValueDescriptor();
pb_table.AUTHREPLY_ERRORCODE_BAD_CHANNEL_ENUM = protobuf.EnumValueDescriptor();
pb_table.AUTHREPLY_CODE_FIELD = protobuf.FieldDescriptor();
pb_table.AUTHREPLY_UID_FIELD = protobuf.FieldDescriptor();
pb_table.AUTHREPLY_HOST_FIELD = protobuf.FieldDescriptor();
pb_table.AUTHREPLY_PORT_FIELD = protobuf.FieldDescriptor();
pb_table.AUTHREPLY_SESSION_ID_FIELD = protobuf.FieldDescriptor();
pb_table.AUTHREPLY_ACCOUNT_FIELD = protobuf.FieldDescriptor();
pb_table.AUTHREPLY_TOKEN_FIELD = protobuf.FieldDescriptor();
pb_table.AUTHREPLY_IM_TOKEN_FIELD = protobuf.FieldDescriptor();

pb_table.LOGINMETHODID_SDK_LOGIN_ENUM.name = "SDK_LOGIN"
pb_table.LOGINMETHODID_SDK_LOGIN_ENUM.index = 0
pb_table.LOGINMETHODID_SDK_LOGIN_ENUM.number = 2000
pb_table.LOGINMETHODID_TOU_LOGIN_ENUM.name = "TOU_LOGIN"
pb_table.LOGINMETHODID_TOU_LOGIN_ENUM.index = 1
pb_table.LOGINMETHODID_TOU_LOGIN_ENUM.number = 2001
pb_table.LOGINMETHODID.name = "LoginMethodID"
pb_table.LOGINMETHODID.full_name = ".LoginMethodID"
pb_table.LOGINMETHODID.values = {pb_table.LOGINMETHODID_SDK_LOGIN_ENUM,pb_table.LOGINMETHODID_TOU_LOGIN_ENUM}
pb_table.DEVICEINFO_PLATFORM_FIELD.name = "platform"
pb_table.DEVICEINFO_PLATFORM_FIELD.full_name = ".DeviceInfo.platform"
pb_table.DEVICEINFO_PLATFORM_FIELD.number = 1
pb_table.DEVICEINFO_PLATFORM_FIELD.index = 0
pb_table.DEVICEINFO_PLATFORM_FIELD.label = 1
pb_table.DEVICEINFO_PLATFORM_FIELD.has_default_value = false
pb_table.DEVICEINFO_PLATFORM_FIELD.default_value = ""
pb_table.DEVICEINFO_PLATFORM_FIELD.type = 9
pb_table.DEVICEINFO_PLATFORM_FIELD.cpp_type = 9

pb_table.DEVICEINFO_PHONE_MODEL_FIELD.name = "phone_model"
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.full_name = ".DeviceInfo.phone_model"
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.number = 2
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.index = 1
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.label = 1
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.has_default_value = false
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.default_value = ""
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.type = 9
pb_table.DEVICEINFO_PHONE_MODEL_FIELD.cpp_type = 9

pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.name = "phone_os_sdk"
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.full_name = ".DeviceInfo.phone_os_sdk"
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.number = 3
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.index = 2
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.label = 1
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.has_default_value = false
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.default_value = ""
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.type = 9
pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD.cpp_type = 9

pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.name = "phone_os_ver"
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.full_name = ".DeviceInfo.phone_os_ver"
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.number = 4
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.index = 3
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.label = 1
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.has_default_value = false
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.default_value = ""
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.type = 9
pb_table.DEVICEINFO_PHONE_OS_VER_FIELD.cpp_type = 9

DEVICEINFO.name = "DeviceInfo"
DEVICEINFO.full_name = ".DeviceInfo"
DEVICEINFO.nested_types = {}
DEVICEINFO.enum_types = {}
DEVICEINFO.fields = {pb_table.DEVICEINFO_PLATFORM_FIELD, pb_table.DEVICEINFO_PHONE_MODEL_FIELD, pb_table.DEVICEINFO_PHONE_OS_SDK_FIELD, pb_table.DEVICEINFO_PHONE_OS_VER_FIELD}
DEVICEINFO.is_extendable = false
DEVICEINFO.extensions = {}
pb_table.CLIENTINFO_VERSION_FIELD.name = "version"
pb_table.CLIENTINFO_VERSION_FIELD.full_name = ".ClientInfo.version"
pb_table.CLIENTINFO_VERSION_FIELD.number = 1
pb_table.CLIENTINFO_VERSION_FIELD.index = 0
pb_table.CLIENTINFO_VERSION_FIELD.label = 2
pb_table.CLIENTINFO_VERSION_FIELD.has_default_value = false
pb_table.CLIENTINFO_VERSION_FIELD.default_value = ""
pb_table.CLIENTINFO_VERSION_FIELD.type = 9
pb_table.CLIENTINFO_VERSION_FIELD.cpp_type = 9

pb_table.CLIENTINFO_CHANNEL_FIELD.name = "channel"
pb_table.CLIENTINFO_CHANNEL_FIELD.full_name = ".ClientInfo.channel"
pb_table.CLIENTINFO_CHANNEL_FIELD.number = 2
pb_table.CLIENTINFO_CHANNEL_FIELD.index = 1
pb_table.CLIENTINFO_CHANNEL_FIELD.label = 2
pb_table.CLIENTINFO_CHANNEL_FIELD.has_default_value = false
pb_table.CLIENTINFO_CHANNEL_FIELD.default_value = ""
pb_table.CLIENTINFO_CHANNEL_FIELD.type = 9
pb_table.CLIENTINFO_CHANNEL_FIELD.cpp_type = 9

pb_table.CLIENTINFO_IP_FIELD.name = "ip"
pb_table.CLIENTINFO_IP_FIELD.full_name = ".ClientInfo.ip"
pb_table.CLIENTINFO_IP_FIELD.number = 3
pb_table.CLIENTINFO_IP_FIELD.index = 2
pb_table.CLIENTINFO_IP_FIELD.label = 2
pb_table.CLIENTINFO_IP_FIELD.has_default_value = false
pb_table.CLIENTINFO_IP_FIELD.default_value = 0
pb_table.CLIENTINFO_IP_FIELD.type = 13
pb_table.CLIENTINFO_IP_FIELD.cpp_type = 3

CLIENTINFO.name = "ClientInfo"
CLIENTINFO.full_name = ".ClientInfo"
CLIENTINFO.nested_types = {}
CLIENTINFO.enum_types = {}
CLIENTINFO.fields = {pb_table.CLIENTINFO_VERSION_FIELD, pb_table.CLIENTINFO_CHANNEL_FIELD, pb_table.CLIENTINFO_IP_FIELD}
CLIENTINFO.is_extendable = false
CLIENTINFO.extensions = {}
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.name = "account"
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.full_name = ".SdkAuthRequest.account"
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.number = 1
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.index = 0
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.label = 1
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.has_default_value = false
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.default_value = ""
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.type = 9
pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD.cpp_type = 9

pb_table.SDKAUTHREQUEST_TOKEN_FIELD.name = "token"
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.full_name = ".SdkAuthRequest.token"
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.number = 2
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.index = 1
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.label = 2
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.has_default_value = false
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.default_value = ""
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.type = 9
pb_table.SDKAUTHREQUEST_TOKEN_FIELD.cpp_type = 9

pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.name = "client_token"
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.full_name = ".SdkAuthRequest.client_token"
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.number = 3
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.index = 2
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.label = 1
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.has_default_value = false
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.default_value = ""
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.type = 9
pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD.cpp_type = 9

pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.name = "sdk_uid"
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.full_name = ".SdkAuthRequest.sdk_uid"
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.number = 4
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.index = 3
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.label = 1
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.has_default_value = false
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.default_value = ""
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.type = 9
pb_table.SDKAUTHREQUEST_SDK_UID_FIELD.cpp_type = 9

pb_table.SDKAUTHREQUEST_CLIENT_FIELD.name = "client"
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.full_name = ".SdkAuthRequest.client"
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.number = 5
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.index = 4
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.label = 2
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.has_default_value = false
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.default_value = nil
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.message_type = CLIENTINFO
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.type = 11
pb_table.SDKAUTHREQUEST_CLIENT_FIELD.cpp_type = 10

pb_table.SDKAUTHREQUEST_DEVICE_FIELD.name = "device"
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.full_name = ".SdkAuthRequest.device"
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.number = 6
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.index = 5
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.label = 1
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.has_default_value = false
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.default_value = nil
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.message_type = DEVICEINFO
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.type = 11
pb_table.SDKAUTHREQUEST_DEVICE_FIELD.cpp_type = 10

pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.name = "platform_id"
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.full_name = ".SdkAuthRequest.platform_id"
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.number = 7
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.index = 6
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.label = 2
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.has_default_value = false
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.default_value = ""
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.type = 9
pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD.cpp_type = 9

SDKAUTHREQUEST.name = "SdkAuthRequest"
SDKAUTHREQUEST.full_name = ".SdkAuthRequest"
SDKAUTHREQUEST.nested_types = {}
SDKAUTHREQUEST.enum_types = {}
SDKAUTHREQUEST.fields = {pb_table.SDKAUTHREQUEST_ACCOUNT_FIELD, pb_table.SDKAUTHREQUEST_TOKEN_FIELD, pb_table.SDKAUTHREQUEST_CLIENT_TOKEN_FIELD, pb_table.SDKAUTHREQUEST_SDK_UID_FIELD, pb_table.SDKAUTHREQUEST_CLIENT_FIELD, pb_table.SDKAUTHREQUEST_DEVICE_FIELD, pb_table.SDKAUTHREQUEST_PLATFORM_ID_FIELD}
SDKAUTHREQUEST.is_extendable = false
SDKAUTHREQUEST.extensions = {}
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.name = "account"
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.full_name = ".TouAuthRequest.account"
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.number = 1
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.index = 0
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.label = 1
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.has_default_value = false
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.default_value = ""
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.type = 9
pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD.cpp_type = 9

pb_table.TOUAUTHREQUEST_CLIENT_FIELD.name = "client"
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.full_name = ".TouAuthRequest.client"
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.number = 2
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.index = 1
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.label = 2
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.has_default_value = false
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.default_value = nil
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.message_type = CLIENTINFO
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.type = 11
pb_table.TOUAUTHREQUEST_CLIENT_FIELD.cpp_type = 10

pb_table.TOUAUTHREQUEST_DEVICE_FIELD.name = "device"
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.full_name = ".TouAuthRequest.device"
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.number = 3
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.index = 2
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.label = 1
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.has_default_value = false
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.default_value = nil
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.message_type = DEVICEINFO
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.type = 11
pb_table.TOUAUTHREQUEST_DEVICE_FIELD.cpp_type = 10

TOUAUTHREQUEST.name = "TouAuthRequest"
TOUAUTHREQUEST.full_name = ".TouAuthRequest"
TOUAUTHREQUEST.nested_types = {}
TOUAUTHREQUEST.enum_types = {}
TOUAUTHREQUEST.fields = {pb_table.TOUAUTHREQUEST_ACCOUNT_FIELD, pb_table.TOUAUTHREQUEST_CLIENT_FIELD, pb_table.TOUAUTHREQUEST_DEVICE_FIELD}
TOUAUTHREQUEST.is_extendable = false
TOUAUTHREQUEST.extensions = {}
pb_table.AUTHREPLY_ERRORCODE_SUCCESS_ENUM.name = "SUCCESS"
pb_table.AUTHREPLY_ERRORCODE_SUCCESS_ENUM.index = 0
pb_table.AUTHREPLY_ERRORCODE_SUCCESS_ENUM.number = 0
pb_table.AUTHREPLY_ERRORCODE_AUTH_FAIL_ENUM.name = "AUTH_FAIL"
pb_table.AUTHREPLY_ERRORCODE_AUTH_FAIL_ENUM.index = 1
pb_table.AUTHREPLY_ERRORCODE_AUTH_FAIL_ENUM.number = 1
pb_table.AUTHREPLY_ERRORCODE_VERSION_ERR_ENUM.name = "VERSION_ERR"
pb_table.AUTHREPLY_ERRORCODE_VERSION_ERR_ENUM.index = 2
pb_table.AUTHREPLY_ERRORCODE_VERSION_ERR_ENUM.number = 2
pb_table.AUTHREPLY_ERRORCODE_BAD_CHANNEL_ENUM.name = "BAD_CHANNEL"
pb_table.AUTHREPLY_ERRORCODE_BAD_CHANNEL_ENUM.index = 3
pb_table.AUTHREPLY_ERRORCODE_BAD_CHANNEL_ENUM.number = 3
pb_table.AUTHREPLY_ERRORCODE.name = "ErrorCode"
pb_table.AUTHREPLY_ERRORCODE.full_name = ".AuthReply.ErrorCode"
pb_table.AUTHREPLY_ERRORCODE.values = {pb_table.AUTHREPLY_ERRORCODE_SUCCESS_ENUM,pb_table.AUTHREPLY_ERRORCODE_AUTH_FAIL_ENUM,pb_table.AUTHREPLY_ERRORCODE_VERSION_ERR_ENUM,pb_table.AUTHREPLY_ERRORCODE_BAD_CHANNEL_ENUM}
pb_table.AUTHREPLY_CODE_FIELD.name = "code"
pb_table.AUTHREPLY_CODE_FIELD.full_name = ".AuthReply.code"
pb_table.AUTHREPLY_CODE_FIELD.number = 1
pb_table.AUTHREPLY_CODE_FIELD.index = 0
pb_table.AUTHREPLY_CODE_FIELD.label = 2
pb_table.AUTHREPLY_CODE_FIELD.has_default_value = false
pb_table.AUTHREPLY_CODE_FIELD.default_value = nil
pb_table.AUTHREPLY_CODE_FIELD.enum_type = AUTHREPLY_ERRORCODE
pb_table.AUTHREPLY_CODE_FIELD.type = 14
pb_table.AUTHREPLY_CODE_FIELD.cpp_type = 8

pb_table.AUTHREPLY_UID_FIELD.name = "uid"
pb_table.AUTHREPLY_UID_FIELD.full_name = ".AuthReply.uid"
pb_table.AUTHREPLY_UID_FIELD.number = 2
pb_table.AUTHREPLY_UID_FIELD.index = 1
pb_table.AUTHREPLY_UID_FIELD.label = 1
pb_table.AUTHREPLY_UID_FIELD.has_default_value = false
pb_table.AUTHREPLY_UID_FIELD.default_value = 0
pb_table.AUTHREPLY_UID_FIELD.type = 13
pb_table.AUTHREPLY_UID_FIELD.cpp_type = 3

pb_table.AUTHREPLY_HOST_FIELD.name = "host"
pb_table.AUTHREPLY_HOST_FIELD.full_name = ".AuthReply.host"
pb_table.AUTHREPLY_HOST_FIELD.number = 3
pb_table.AUTHREPLY_HOST_FIELD.index = 2
pb_table.AUTHREPLY_HOST_FIELD.label = 1
pb_table.AUTHREPLY_HOST_FIELD.has_default_value = false
pb_table.AUTHREPLY_HOST_FIELD.default_value = ""
pb_table.AUTHREPLY_HOST_FIELD.type = 9
pb_table.AUTHREPLY_HOST_FIELD.cpp_type = 9

pb_table.AUTHREPLY_PORT_FIELD.name = "port"
pb_table.AUTHREPLY_PORT_FIELD.full_name = ".AuthReply.port"
pb_table.AUTHREPLY_PORT_FIELD.number = 4
pb_table.AUTHREPLY_PORT_FIELD.index = 3
pb_table.AUTHREPLY_PORT_FIELD.label = 1
pb_table.AUTHREPLY_PORT_FIELD.has_default_value = false
pb_table.AUTHREPLY_PORT_FIELD.default_value = 0
pb_table.AUTHREPLY_PORT_FIELD.type = 13
pb_table.AUTHREPLY_PORT_FIELD.cpp_type = 3

pb_table.AUTHREPLY_SESSION_ID_FIELD.name = "session_id"
pb_table.AUTHREPLY_SESSION_ID_FIELD.full_name = ".AuthReply.session_id"
pb_table.AUTHREPLY_SESSION_ID_FIELD.number = 5
pb_table.AUTHREPLY_SESSION_ID_FIELD.index = 4
pb_table.AUTHREPLY_SESSION_ID_FIELD.label = 1
pb_table.AUTHREPLY_SESSION_ID_FIELD.has_default_value = false
pb_table.AUTHREPLY_SESSION_ID_FIELD.default_value = ""
pb_table.AUTHREPLY_SESSION_ID_FIELD.type = 9
pb_table.AUTHREPLY_SESSION_ID_FIELD.cpp_type = 9

pb_table.AUTHREPLY_ACCOUNT_FIELD.name = "account"
pb_table.AUTHREPLY_ACCOUNT_FIELD.full_name = ".AuthReply.account"
pb_table.AUTHREPLY_ACCOUNT_FIELD.number = 6
pb_table.AUTHREPLY_ACCOUNT_FIELD.index = 5
pb_table.AUTHREPLY_ACCOUNT_FIELD.label = 1
pb_table.AUTHREPLY_ACCOUNT_FIELD.has_default_value = false
pb_table.AUTHREPLY_ACCOUNT_FIELD.default_value = ""
pb_table.AUTHREPLY_ACCOUNT_FIELD.type = 9
pb_table.AUTHREPLY_ACCOUNT_FIELD.cpp_type = 9

pb_table.AUTHREPLY_TOKEN_FIELD.name = "token"
pb_table.AUTHREPLY_TOKEN_FIELD.full_name = ".AuthReply.token"
pb_table.AUTHREPLY_TOKEN_FIELD.number = 7
pb_table.AUTHREPLY_TOKEN_FIELD.index = 6
pb_table.AUTHREPLY_TOKEN_FIELD.label = 1
pb_table.AUTHREPLY_TOKEN_FIELD.has_default_value = false
pb_table.AUTHREPLY_TOKEN_FIELD.default_value = ""
pb_table.AUTHREPLY_TOKEN_FIELD.type = 9
pb_table.AUTHREPLY_TOKEN_FIELD.cpp_type = 9

pb_table.AUTHREPLY_IM_TOKEN_FIELD.name = "im_token"
pb_table.AUTHREPLY_IM_TOKEN_FIELD.full_name = ".AuthReply.im_token"
pb_table.AUTHREPLY_IM_TOKEN_FIELD.number = 8
pb_table.AUTHREPLY_IM_TOKEN_FIELD.index = 7
pb_table.AUTHREPLY_IM_TOKEN_FIELD.label = 1
pb_table.AUTHREPLY_IM_TOKEN_FIELD.has_default_value = false
pb_table.AUTHREPLY_IM_TOKEN_FIELD.default_value = ""
pb_table.AUTHREPLY_IM_TOKEN_FIELD.type = 9
pb_table.AUTHREPLY_IM_TOKEN_FIELD.cpp_type = 9

AUTHREPLY.name = "AuthReply"
AUTHREPLY.full_name = ".AuthReply"
AUTHREPLY.nested_types = {}
AUTHREPLY.enum_types = {pb_table.AUTHREPLY_ERRORCODE}
AUTHREPLY.fields = {pb_table.AUTHREPLY_CODE_FIELD, pb_table.AUTHREPLY_UID_FIELD, pb_table.AUTHREPLY_HOST_FIELD, pb_table.AUTHREPLY_PORT_FIELD, pb_table.AUTHREPLY_SESSION_ID_FIELD, pb_table.AUTHREPLY_ACCOUNT_FIELD, pb_table.AUTHREPLY_TOKEN_FIELD, pb_table.AUTHREPLY_IM_TOKEN_FIELD}
AUTHREPLY.is_extendable = false
AUTHREPLY.extensions = {}

AuthReply = protobuf.Message(AUTHREPLY)
ClientInfo = protobuf.Message(CLIENTINFO)
DeviceInfo = protobuf.Message(DEVICEINFO)
SDK_LOGIN = 2000
SdkAuthRequest = protobuf.Message(SDKAUTHREQUEST)
TOU_LOGIN = 2001
TouAuthRequest = protobuf.Message(TOUAUTHREQUEST)
