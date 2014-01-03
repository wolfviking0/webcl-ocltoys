#
#  Makefile
#
#  Created by Anthony Liot.
#  Copyright (c) 2013 Anthony Liot. All rights reserved.
#

EMCC:=../../../webcl-translator/emscripten
BOOST:=../../../boost

EMSCRIPTEN = $(EMCC)
CXX = $(EMSCRIPTEN)/emcc
AR = $(EMSCRIPTEN)/emar
EMCONFIGURE = $(EMSCRIPTEN)/emconfigure
EMMAKE = $(EMSCRIPTEN)/emmake

CHDIR_SHELL := $(SHELL)
define chdir
   $(eval _D=$(firstword $(1) $(@D)))
   $(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

DEB=0
VAL=0

ifeq ($(VAL),1)
PREFIX = val_
VALIDATOR = '["-DPARAM_MAX_DEPTH","-DPARAM_DEFAULT_SIGMA_S","-DPARAM_DEFAULT_SIGMA_A"]' # Enable validator without parameter
$(info ************  Mode VALIDATOR : Enabled ************)
else
PREFIX = 
VALIDATOR = '[]' # disable validator
$(info ************  Mode VALIDATOR : Disabled ************)
endif

DEBUG = -O0 -s CL_VALIDATOR=$(VAL) -s CL_VAL_PARAM=$(VALIDATOR) -s CL_PRINT_TRACE=1 -s DISABLE_EXCEPTION_CATCHING=0 -s WARN_ON_UNDEFINED_SYMBOLS=1 -s CL_PROFILE=1 -s CL_DEBUG=1 -s CL_GRAB_TRACE=1 -s CL_CHECK_VALID_OBJECT=1

NO_DEBUG = -02 -s CL_VALIDATOR=$(VAL) -s CL_VAL_PARAM=$(VALIDATOR) -s WARN_ON_UNDEFINED_SYMBOLS=0 -s CL_PROFILE=1 -s CL_DEBUG=0 -s CL_GRAB_TRACE=0 -s CL_PRINT_TRACE=0 -s CL_CHECK_VALID_OBJECT=0

ifeq ($(DEB),1)
MODE=$(DEBUG)
EMCCDEBUG = EMCC_DEBUG
$(info ************  Mode DEBUG : Enabled ************)
else
MODE=$(NO_DEBUG)
EMCCDEBUG = EMCCDEBUG
$(info ************  Mode DEBUG : Disabled ************)
endif

$(info )
$(info )

#----------------------------------------------------------------------------------------#
#----------------------------------------------------------------------------------------#
# BUILD
#----------------------------------------------------------------------------------------#
#----------------------------------------------------------------------------------------#		

BOOST_SRC = \
		$(BOOST)/libs/system/src/error_code.cpp \
		$(BOOST)/libs/program_options/src/options_description.cpp \
		$(BOOST)/libs/program_options/src/cmdline.cpp \
		$(BOOST)/libs/program_options/src/variables_map.cpp \
		$(BOOST)/libs/program_options/src/value_semantic.cpp \
		$(BOOST)/libs/program_options/src/positional_options.cpp \
		$(BOOST)/libs/program_options/src/convert.cpp \
		$(BOOST)/libs/regex/src/regex.cpp \
		$(BOOST)/libs/regex/src/cpp_regex_traits.cpp \
		$(BOOST)/libs/regex/src/regex_raw_buffer.cpp \
		$(BOOST)/libs/regex/src/regex_traits_defaults.cpp \
		$(BOOST)/libs/regex/src/static_mutex.cpp \
		$(BOOST)/libs/regex/src/instances.cpp \
		$(BOOST)/libs/filesystem/src/operations.cpp \

COMMON_SRC = \
		../../ocltoys-v1.0/common/ocltoy.cpp \
		../../ocltoys-v1.0/common/utils.cpp \

all: build_lib all_1 all_2 all_3

all_1: \
	jugCLer_sample \

all_2: \
	juliagpu_sample \

all_3: \
	mandelgpu_sample \
	smallptgpu_sample \

build_lib:
	$(call chdir,externs/lib/)
	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) $(COMMON_SRC) -I$(BOOST) -I../../ocltoys-v1.0/common/ -o libcommon.o
	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) $(BOOST_SRC) -I../../externs/include/ -o libboost.o	

jugCLer_sample:
	$(call chdir,ocltoys-v1.0/jugCLer/)
	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
		animation.cpp \
		jugCLer.cpp \
		scene.cpp \
		../../externs/lib/libcommon.o \
		../../externs/lib/libboost.o \
	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 \
	-I../common/ \
	-I../../externs/include/ \
	--preload-file trace.cl \
	-o ../../build/$(PREFIX)toys_jugCLer.js

juliagpu_sample:
	$(call chdir,ocltoys-v1.0/juliagpu/)
	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
		juliagpu.cpp \
		../../externs/lib/libcommon.o \
		../../externs/lib/libboost.o \
	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 \
	-I../common/ \
	-I../../externs/include/ \
	--preload-file preprocessed_rendering_kernel.cl \
	--preload-file rendering_kernel.cl \
	-o ../../build/$(PREFIX)toys_juliagpu.js

mandelgpu_sample:
	$(call chdir,ocltoys-v1.0/mandelgpu/)
	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
		mandelgpu.cpp \
		../../externs/lib/libcommon.o \
		../../externs/lib/libboost.o \
	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 \
	-I../common/ \
	-I../../externs/include/ \
	--preload-file rendering_kernel_float4.cl \
	--preload-file rendering_kernel.cl \
	-o ../../build/$(PREFIX)toys_mandelgpu.js

smallptgpu_sample:
	$(call chdir,ocltoys-v1.0/smallptgpu/)
	JAVA_HEAP_SIZE=8096m $(EMCCDEBUG)=1 $(CXX) \
		smallptgpu.cpp \
		../../externs/lib/libcommon.o \
		../../externs/lib/libboost.o \
	$(MODE) -s GL_FFP_ONLY=1 -s LEGACY_GL_EMULATION=1 -s TOTAL_MEMORY=1024*1024*100 \
	-I../common/ \
	-I../../externs/include/ \
	--preload-file preprocessed_rendering_kernel.cl \
	--preload-file scenes/caustic.scn \
	--preload-file scenes/caustic3.scn \
	--preload-file scenes/cornell_fog.scn \
	--preload-file scenes/cornell_large.scn \
	--preload-file scenes/cornell_sss.scn \
	--preload-file scenes/cornell.scn \
	--preload-file scenes/simple.scn \
	-o ../../build/$(PREFIX)toys_smallptgpu.js

juliagpu_sample_osx:
	$(call chdir,ocltoys-v1.0/juliagpu/)
	clang++ \
		juliagpu.cpp \
		$(COMMON_SRC) \
		$(BOOST_SRC) \
		-D__EMSCRIPTEN__ \
		-I../common/ \
		-I../../externs/include/ \
		-I ./ -I $(EMCC)/system/include/ -framework OpenCL -framework OpenGL -framework GLUT \
		-lboost_filesystem-mt -lboost_program_options-mt \
		-o juliagpu.out
		
smallptgpu_sample_osx:
	$(call chdir,ocltoys-v1.0/smallptgpu/)
	clang++ \
		smallptgpu.cpp \
		$(COMMON_SRC) \
		$(BOOST_SRC) \
		-D__EMSCRIPTEN__ \
		-I../common/ \
		-I../../externs/include/ \
		-I ./ -I $(EMCC)/system/include/ -framework OpenCL -framework OpenGL -framework GLUT \
		-lboost_filesystem-mt -lboost_program_options-mt \
		-o smallptgpu.out

clean:
	$(call chdir,build/)
	rm -rf tmp/	
	mkdir tmp
	cp memoryprofiler.js tmp/
	cp settings.js tmp/
	rm -f *.data
	rm -f *.js
	rm -f *.map
	cp tmp/memoryprofiler.js ./
	cp tmp/settings.js ./
	rm -rf tmp/
	../../webcl-translator/emscripten/emcc --clear-cache

