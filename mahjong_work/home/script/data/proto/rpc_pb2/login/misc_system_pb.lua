-- Generated By protoc-gen-lua Do not Edit
local protobuf = import("net/protobuf/protobuf.lua")


local METHODID = protobuf.EnumDescriptor();
local METHODID_PING_ENUM = protobuf.EnumValueDescriptor();
PINGREQUEST = protobuf.Descriptor();
PINGREPLY = protobuf.Descriptor();
local PINGREPLY_TIMESTAMP_FIELD = protobuf.FieldDescriptor();

METHODID_PING_ENUM.name = "PING"
METHODID_PING_ENUM.index = 0
METHODID_PING_ENUM.number = 0
METHODID.name = "MethodID"
METHODID.full_name = ".MethodID"
METHODID.values = {METHODID_PING_ENUM}
PINGREQUEST.name = "PingRequest"
PINGREQUEST.full_name = ".PingRequest"
PINGREQUEST.nested_types = {}
PINGREQUEST.enum_types = {}
PINGREQUEST.fields = {}
PINGREQUEST.is_extendable = false
PINGREQUEST.extensions = {}
PINGREPLY_TIMESTAMP_FIELD.name = "timestamp"
PINGREPLY_TIMESTAMP_FIELD.full_name = ".PingReply.timestamp"
PINGREPLY_TIMESTAMP_FIELD.number = 1
PINGREPLY_TIMESTAMP_FIELD.index = 0
PINGREPLY_TIMESTAMP_FIELD.label = 2
PINGREPLY_TIMESTAMP_FIELD.has_default_value = false
PINGREPLY_TIMESTAMP_FIELD.default_value = 0
PINGREPLY_TIMESTAMP_FIELD.type = 13
PINGREPLY_TIMESTAMP_FIELD.cpp_type = 3

PINGREPLY.name = "PingReply"
PINGREPLY.full_name = ".PingReply"
PINGREPLY.nested_types = {}
PINGREPLY.enum_types = {}
PINGREPLY.fields = {PINGREPLY_TIMESTAMP_FIELD}
PINGREPLY.is_extendable = false
PINGREPLY.extensions = {}

PING = 0
PingReply = protobuf.Message(PINGREPLY)
PingRequest = protobuf.Message(PINGREQUEST)
