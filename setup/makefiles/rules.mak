ifneq (,$(wildcard $(OSPL_HOME)/setup/$(SPLICE_TARGET)))
include $(OSPL_HOME)/setup/$(SPLICE_TARGET)/config.mak
else
include $(OSPL_OUTER_HOME)/setup/$(SPLICE_TARGET)/config.mak
endif

ifdef FLEX_HOME
FLEX_LM_NEW     ?= lm_new$(OBJ_POSTFIX)
endif

# This makefile defined the platform and component independent make rules.
CLASS_DIR  =bld/$(SPLICE_TARGET)
JCODE_DIR  ?=code
JFLAGS    ?= -source 1.4
JFLAGS    +=-sourcepath '$(JCODE_DIR)'
MANIFEST   =manifest/$(SPLICE_TARGET)/manifest.mf

# If JAR_MODULE is not defined, assign something to prevent warnings in make
# output.
JAR_MODULE ?= foo
JAR_TARGET =$(JAR_LOCATION)/jar/$(SPLICE_TARGET)
JAR_FILE   =$(JAR_TARGET)/$(JAR_MODULE)

ifdef JAVA_MAIN_CLASS
MANIFEST_MAIN=Main-Class: $(JAVA_MAIN_CLASS)
endif

ifdef JAVA_INC
ifeq (,$(findstring mingw,$(SPLICE_TARGET))) 
MANIFEST_CLASSPATH=Class-Path: $(notdir $(subst :, ,$(JAVA_INC)))
#MANIFEST_CLASSPATH=Class-Path: $(subst $(JAR_INC_DIR)/,,$(subst :, ,$(JAVA_INC)))
else
MANIFEST_CLASSPATH=Class-Path: $(notdir $(subst ;, ,$(JAVA_INC)))
endif
endif

$(CLASS_DIR):
	mkdir -p $(CLASS_DIR)

LOCAL_CLASS_DIR	=$(CLASS_DIR)/$(PACKAGE_DIR)

# EXTRA_INC is only needed for cygwin builds to split the INCLUDE length as when it
# exceeds a certain length make doesn't like it.

.PRECIOUS: %.c %.h

(%.o): %.o
	$(AR) r $@ $<

ifeq (,$(findstring win32,$(SPLICE_TARGET)))
%.d: %.c
	$(CPP) $(MAKEDEPFLAGS) $(CPPFLAGS) $(INCLUDE) $< >$@
else
%.d: %.c
	$(CPP) $(MAKEDEPFLAGS) $(CPPFLAGS) $(INCLUDE) $(EXTRA_INC) $< | sed 's@ [A-Za-z]\:@ /cygdrive/$(CYGWIN_INSTALL_DRIVE)/@' | sed 's#\.o#$(OBJ_POSTFIX)#g' >$@
endif

ifeq (,$(findstring win32,$(SPLICE_TARGET)))
%.d: %.cpp
	$(GCPP) $(MAKEDEPFLAGS) $(CPPFLAGS) $(INCLUDE) $< >$@
else
%.d: %.cpp
	$(GCPP) $(MAKEDEPFLAGS) $(CPPFLAGS) $(INCLUDE) $(EXTRA_INC) $< | sed 's@ [A-Za-z]\:@ /cygdrive/$(CYGWIN_INSTALL_DRIVE)/@' | sed 's#\.o#$(OBJ_POSTFIX)#g' >$@
endif

%$(OBJ_POSTFIX): %.c
	$(FILTER) $(CC) $(CPPFLAGS) $(CFLAGS) $(INCLUDE) $(EXTRA_INC) -c $<

%$(OBJ_POSTFIX): %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(INCLUDE) $(EXTRA_INC) -c $<

%$(OBJ_POSTFIX): %.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(INCLUDE) $(EXTRA_INC) -c $<

%.c: %.y
	$(YACC) $< -o $@

%.h: %.l
	$(LEX) -t $< > $@

%.c.met: %.c
	$(QAC) $(CPFLAGS) $(INCLUDE) $<

%.c.gcov: %.bb
	$(GCOV) -b -f $< > $@.sum

$(CLASS_DIR)/%.class: $(JCODE_DIR)/%.java 
ifeq (,$(findstring win32,$(SPLICE_TARGET))) 
	$(JCC) -classpath $(CLASS_DIR):$(JAVA_INC) $(JFLAGS) -d $(CLASS_DIR) $(JCFLAGS) $(dir $<)*.java
else
	$(JCC) -classpath '$(CLASS_DIR);$(JAVA_INC)' $(JFLAGS) -d $(CLASS_DIR) $(JCFLAGS) $(dir $<)*.java
endif

CODE_DIR	?= ../../code

vpath %.c		$(CODE_DIR)
vpath %.cpp		$(CODE_DIR)
vpath %.y		$(CODE_DIR)
vpath %.l		$(CODE_DIR)
vpath %.odl		$(CODE_DIR)
#vpath %.class 	$(LOCAL_CLASS_DIR)
vpath %.idl	$(CODE_DIR)
INCLUDE		 = -I.
INCLUDE		+= -I../../include
INCLUDE		+= -I$(CODE_DIR)

ifndef OSPL_OUTER_HOME
INCLUDE		+= -I$(OSPL_HOME)/src/include
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os-net/include
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os-net/$(OS)$(OS_REV)
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os/include
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os/$(OS)$(OS_REV)
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/pa/$(PROC_CORE)
else
INCLUDE		+= -I$(OSPL_HOME)/src/include
INCLUDE		+= -I$(OSPL_OUTER_HOME)/src/abstraction/os-net/include
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os-net/include
INCLUDE		+= -I$(OSPL_OUTER_HOME)/src/abstraction/os-net/$(OS)$(OS_REV)
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os-net/$(OS)$(OS_REV)
INCLUDE		+= -I$(OSPL_OUTER_HOME)/src/abstraction/os/include
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os/include
INCLUDE		+= -I$(OSPL_OUTER_HOME)/src/abstraction/os/$(OS)$(OS_REV)
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/os/$(OS)$(OS_REV)
INCLUDE		+= -I$(OSPL_OUTER_HOME)/src/abstraction/pa/$(PROC_CORE)
INCLUDE		+= -I$(OSPL_HOME)/src/abstraction/pa/$(PROC_CORE)
endif

C_FILES		?= $(notdir $(wildcard $(CODE_DIR)/*.c)) 
CPP_FILES	?= $(notdir $(wildcard $(CODE_DIR)/*.cpp))
Y_FILES		:= $(notdir $(wildcard $(CODE_DIR)/*.y))
L_FILES		:= $(notdir $(wildcard $(CODE_DIR)/*.l))
ODL_FILES	= $(notdir $(wildcard $(CODE_DIR)/*.odl))
GCOV_FILES	:= $(notdir $(wildcard *.bb))
JAVA_FILES	= $(wildcard $(addsuffix /*.java,$(addprefix code/,$(JPACKAGES))))
CLASS_FILES = $(subst .java,.class,$(subst $(JCODE_DIR),$(CLASS_DIR),$(JAVA_FILES)))

ODL_H		:= $(addsuffix .h,$(ODL_MODULES))
ODL_C		:= $(addsuffix .c,$(ODL_MODULES))
ODL_O		:= $(addsuffix $(OBJ_POSTFIX),$(ODL_MODULES))

OBJECTS		:= $(C_FILES:%.c=%$(OBJ_POSTFIX)) $(CPP_FILES:%.cpp=%$(OBJ_POSTFIX)) $(Y_FILES:%.y=%$(OBJ_POSTFIX)) $(ODL_O) $(IDL_O)
DEPENDENCIES	:= $(C_FILES:%.c=%.d) $(CPP_FILES:%.cpp=%.d) $(Y_FILES:%.y=%.d) $(ODL_C:%.c=%.d)
EXECUTABLES     := $(basename $(OBJECTS))
H_FILES		:= $(L_FILES:%.l=%.h)
QAC_FILES	:= $(C_FILES:%.c=%.c.met) # $(CPP_FILES:%.cpp=%.cpp.met)
GCOV_RESULT	:= $(GCOV_FILES:%.bb=%.c.gcov)

$(H_FILES): $(L_FILES) #$(ODL_FILES) $(IDL_FILES)
#$(OBJECTS): $(C_FILES) $(CPP_FILES) $(Y_FILES:%.y=%.c) $(ODL_C)
#$(DEPENDENCIES): $(C_FILES) $(CPP_FILES) $(Y_FILES:%.y=%.c) $(H_FILES) $(ODL_H)
$(DEPENDENCIES): $(H_FILES) $(ODL_H) $(IDL_H)

$(ODL_H): $(ODL_FILES)
	sh $(OSPL_HOME)/bin/sppodl $(SPPODL_FLAGS) $<
	cp $(ODL_H)  $(OSPL_HOME)/src/include

$(ODL_C): $(ODL_FILES)
	sh $(OSPL_HOME)/bin/sppodl $(SPPODL_FLAGS) $<
	cp $(ODL_H)  $(OSPL_HOME)/src/include

jar: $(JAR_FILE)

$(JAR_FILE): $(JAR_DEPENDENCIES) $(CLASS_DIR) $(CLASS_FILES) $(JAR_TARGET) $(MANIFEST)
	$(JAR) cmf $(MANIFEST) $(JAR_FILE) -C bld/$(SPLICE_TARGET) .

ifdef MANIFEST_CLASSPATH
$(MANIFEST):
	@mkdir -p manifest/$(SPLICE_TARGET)
	@touch -a $(MANIFEST)
	@printf "%s\n%s\n" "$(MANIFEST_CLASSPATH)" "$(MANIFEST_MAIN)" > $(MANIFEST)
else
$(MANIFEST):
	@mkdir -p manifest/$(SPLICE_TARGET)
	@touch -a $(MANIFEST)
	@printf "%s\n" "$(MANIFEST_MAIN)" > $(MANIFEST)
endif

$(JAR_TARGET):
	@mkdir -p $(JAR_LOCATION)/jar/$(SPLICE_TARGET)
