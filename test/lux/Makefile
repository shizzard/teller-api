SUBDIRS = `ls . | grep -v '^__'` ## ignore directories masked with '__'
TEST_ROOT := $(abspath ./)

.PHONY: all build clean

all build clean:
	@for d in $(SUBDIRS); do \
		if [ -f $$d/Makefile ] ; then \
			$(MAKE) -C $$d $@ || exit $$?; \
		fi; \
	done
