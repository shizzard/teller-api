################################################################################
# Prepare

APPLICATION_ROOT := $(abspath ./)
APPLICATION_EXEC := $(APPLICATION_ROOT)/_build/dev/rel/teller_api/bin/teller_api
MIX := $(shell which mix)
LUX_ROOT := $(APPLICATION_ROOT)/_tools/lux
LUX := $(LUX_ROOT)/bin/lux
LUX_TESTS_ROOT := $(APPLICATION_ROOT)/test/lux

ifeq (, $(MIX))
$(error "No mix found, is elixir installed?")
endif

define print_app_env
	@echo "--   Application ENV  --"
	@printenv | grep ^TELLER_API_$(1) | grep -v print_app_env
	@echo "--   Application ENV  --"
endef


################################################################################
# Environment

.EXPORT_ALL_VARIABLES:

RELX_REPLACE_OS_VARS ?= true

## VMARGS variables should also be defined here when preparing for production
## environments. Skip it for now.
# TELLER_VMARGS_... ?= ...

TELLER_API_LOGGER_LEVEL ?= debug

TELLER_API_PROCGEN_SECRET_KEY_B36 ?= devkey
TELLER_API_PROCGEN_SECRET_KEY_B36_BASE ?= 64
TELLER_API_PROCGEN_ACCOUNTS_ID_BASE ?= 32
TELLER_API_PROCGEN_ACCOUNTS_ENROLLMENT_ID_BASE ?= 32
TELLER_API_PROCGEN_ACCOUNTS_ROUTING_NUMBERS_ACH ?= 32
TELLER_API_PROCGEN_ACCOUNTS_PER_TOKEN_MAX ?= 3
TELLER_API_PROCGEN_TRANSACTIONS_ID_BASE ?= 32
TELLER_API_PROCGEN_TRANSACTIONS_DAYS_PER_ACCOUNT ?= 5
TELLER_API_PROCGEN_TRANSACTIONS_PER_DAY_MAX ?= 3
TELLER_API_PROCGEN_TRANSACTIONS_AMOUNT_MIN ?= 10
TELLER_API_PROCGEN_TRANSACTIONS_AMOUNT_MAX ?= 100
TELLER_API_PROCGEN_TRANSACTIONS_STATUS_POSTED_CHANCE ?= 0.8
TELLER_API_PROCGEN_TRANSACTIONS_PROCESSING_STATUS_COMPLETE_CHANCE ?= 0.9

TELLER_API_HTTP_PROTO ?= "http"
TELLER_API_HTTP_HOST ?= "localhost"


################################################################################
# Build targets

.PHONY: all get-deps compile run

all: get-deps $(APPLICATION_EXEC)

get-deps:
	$(MIX) deps.get

compile:
	$(MIX) compile

$(APPLICATION_EXEC): compile
	$(MIX) release --overwrite

run: $(APPLICATION_EXEC)
	$(call print_app_env)
	$(APPLICATION_ROOT)/_build/dev/rel/teller_api/bin/teller_api start_iex


################################################################################
# Test targets

.PHONY: check check-format check-dialyze unit-tests lux-tests

check: check-format check-dialyze unit-tests lux-tests

check-format:
	@echo "=====  FORMAT RUN  ====="
	$(MIX) format --check-formatted --dry-run
	@echo "=====  FORMAT END  ====="

check-dialyze:
	@echo "===== DIALYZER RUN ====="
	@echo "Dialyzer run skipped"
	@echo "===== DIALYZER END ====="

unit-tests:
	@echo "=====   EUNIT RUN  ====="
	$(MIX) test
	@echo "=====   EUNIT END  ====="

lux-tests: $(LUX)
	@echo "=====    LUX RUN   ====="
	$(call print_app_env)
	$(MAKE) -C $(LUX_TESTS_ROOT) || exit $$?
	$(LUX) --html enable $(LUX_TESTS_ROOT)
	@echo "=====    LUX END   ====="

$(LUX):
	git clone https://github.com/hawk/lux.git $(LUX_ROOT)
	@cd $(LUX_ROOT) && autoconf && ./configure && make


################################################################################
# Clean targets

.PHONY: clean distclean

clean:
	$(MIX) clean
	$(MIX) clean --deps

distclean:
	rm -rf _build

