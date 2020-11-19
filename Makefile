PROJECT_NAME := main

EXTRA_COMPONENT_DIRS := $(IDF_PATH)/examples/common_components/protocol_examples_common
EXTRA_COMPONENT_DIRS += $(IDF_PATH)/esp-idf-lib-master/components

EXCLUDE_COMPONENTS := max7219 mcp23x17 led_strip

include $(IDF_PATH)/make/project.mk