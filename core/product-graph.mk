#
# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# the sort also acts as a strip to remove the single space entries that creep in because of the evals
define gather-all-products
$(eval _all_products_visited := )\
$(sort $(call all-products-inner, $(PARENT_PRODUCT_FILES)))
endef

define all-products-inner
	$(foreach p,$(1),\
		$(if $(filter $(p),$(_all_products_visited)),, \
			$(p) \
			$(eval _all_products_visited += $(p)) \
			$(call all-products-inner, $(PRODUCTS.$(strip $(p)).INHERITS_FROM))
		) \
	)
endef

this_makefile := build/make/core/product-graph.mk

products_graph := $(OUT_DIR)/products.dot
ifeq ($(strip $(ANDROID_PRODUCT_GRAPH)),)
products_list := $(INTERNAL_PRODUCT)
else
ifeq ($(strip $(ANDROID_PRODUCT_GRAPH)),--all)
products_list := --all
else
products_list := $(foreach prod,$(ANDROID_PRODUCT_GRAPH),$(call resolve-short-product-name,$(prod)))
endif
endif

all_products := $(call gather-all-products)

open_parethesis := (
close_parenthesis := )

node_color_target := orange
node_color_common := beige
node_color_vendor := lavenderblush
node_color_default := white
define node-color
$(if $(filter $(1),$(PRIVATE_PRODUCTS_FILTER)),\
  $(node_color_target),\
  $(if $(filter build/make/target/product/%,$(1)),\
    $(node_color_common),\
    $(if $(filter vendor/%,$(1)),$(node_color_vendor),$(node_color_default))\
  )\
)
endef

# Emit properties of a product node to a file.
# $(1) the product
# $(2) the output file
define emit-product-node-props
$(hide) echo \"$(1)\" [ \
label=\"$(dir $(1))\\n$(notdir $(1))\\n\\n$(subst $(close_parenthesis),,$(subst $(open_parethesis),,$(call get-product-var,$(1),PRODUCT_MODEL)))\\n$(call get-product-var,$(1),PRODUCT_DEVICE)\" \
style=\"filled\" fillcolor=\"$(strip $(call node-color,$(1)))\" \
colorscheme=\"svg\" fontcolor=\"darkblue\" \
] >> $(2)

endef

$(products_graph): PRIVATE_PRODUCTS := $(all_products)
$(products_graph): PRIVATE_PRODUCTS_FILTER := $(products_list)

$(products_graph): $(this_makefile)
ifeq (,$(RBC_PRODUCT_CONFIG)$(RBC_NO_PRODUCT_GRAPH)$(RBC_BOARD_CONFIG))
	@echo Product graph DOT: $@ for $(PRIVATE_PRODUCTS_FILTER)
	$(hide) echo 'digraph {' > $@.in
	$(hide) echo 'graph [ ratio=.5 ];' >> $@.in
	$(hide) $(foreach p,$(PRIVATE_PRODUCTS), \
	  $(foreach d,$(PRODUCTS.$(strip $(p)).INHERITS_FROM), echo \"$(d)\" -\> \"$(p)\" >> $@.in;))
	$(foreach p,$(PRIVATE_PRODUCTS),$(call emit-product-node-props,$(p),$@.in))
	$(hide) echo '}' >> $@.in
	$(hide) build/make/tools/filter-product-graph.py $(PRIVATE_PRODUCTS_FILTER) < $@.in > $@
else
	@echo RBC_PRODUCT_CONFIG and RBC_NO_PRODUCT_GRAPH should be unset to generate product graph
	false
endif

ifeq (,$(RBC_PRODUCT_CONFIG)$(RBC_NO_PRODUCT_GRAPH)$(RBC_BOARD_CONFIG))

.PHONY: product-graph
product-graph: $(products_graph)
	@echo Product graph .dot file: $(products_graph)
	@echo Command to convert to pdf: dot -Tpdf -Nshape=box -o $(OUT_DIR)/products.pdf $(products_graph)
	@echo Command to convert to svg: dot -Tsvg -Nshape=box -o $(OUT_DIR)/products.svg $(products_graph)
else
.PHONY: product-graph
	@echo RBC_PRODUCT_CONFIG and RBC_NO_PRODUCT_GRAPH should be unset to generate product graph
	false
endif
