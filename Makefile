PROJ_NAME=main

DEBUG=1

SRCS = src/main.c \
       src/system_stm32f4xx.c \
       src/startup_stm32f4xx.s


CC=arm-none-eabi-gcc
GDB=arm-none-eabi-gdb
OBJCOPY=arm-none-eabi-objcopy

OBJDIR = build

ifdef DEBUG
CFLAGS  = -O0 -g3 -MMD
else
CFLAGS  = -O2 -finline -finline-functions-called-once
endif
CFLAGS += -Wall -Wno-missing-braces -std=c99 -mthumb -mcpu=cortex-m4
#CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m4 -mthumb-interwork
#CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS += -mfloat-abi=soft
# TODO: hard float was causing an exception; see what's up.
LDFLAGS = -Wl,-Map,$(OBJDIR)/$(PROJ_NAME).map -g -Tstm32f4_flash.ld
DEFINES =  -DUSE_STDPERIPH_DRIVER
export DEFINES

LIBROOT := ../stm32-lib
FWROOT := $(LIBROOT)/STM32F4xx_StdPeriph_Driver
FWLIB := $(FWROOT)/libstm32fw.a

CFLAGS += $(DEFINES) -Isrc -I. -I $(FWROOT) -I $(FWROOT)/inc -I $(LIBROOT)/CMSIS_CM4/ST/STM32F4xx/Include -I $(LIBROOT)/CMSIS_CM4/Include

OBJS := $(SRCS:.c=.o)
OBJS := $(OBJS:.s=.o)
OBJS := $(addprefix $(OBJDIR)/,$(OBJS))


all: proj

$(FWLIB): $(wildcard $(LIBROOT)/STM32F4xx_StdPeriph_Driver/*.h) $(wildcard $(LIBROOT)/STM32F4xx_StdPeriph_Driver/inc/*.h)
	@cd $(FWROOT) && $(MAKE)

proj: $(FWLIB) $(OBJDIR)/$(PROJ_NAME).elf $(OBJDIR)/$(PROJ_NAME).hex $(OBJDIR)/$(PROJ_NAME).bin

$(OBJDIR)/%.elf: $(OBJS) $(FWLIB)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.hex: %.elf
	$(OBJCOPY) -O ihex $^ $@

%.bin: %.elf
	$(OBJCOPY) -O binary $^ $@

$(OBJDIR)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $^

$(OBJDIR)/%.o: %.s
	$(CC) -c $(CFLAGS) -o $@ $^

$(OBJDIR):
	mkdir -p $@

clean:
	rm -f $(OBJDIR)/$(PROJ_NAME).elf
	rm -f $(OBJDIR)/$(PROJ_NAME).hex
	rm -f $(OBJDIR)/$(PROJ_NAME).bin
	rm -f $(OBJDIR)/$(PROJ_NAME).map
	find $(OBJDIR) -type f -name '*.[odt]' -print0 | xargs -0 -r rm


flash: $(OBJDIR)/$(PROJ_NAME).elf
	openocd -f interface/stlink-v2.cfg -f target/stm32f4x_stlink.cfg -f program.cfg

openocd:
	openocd -f interface/stlink-v2.cfg -f target/stm32f4x_stlink.cfg

gdb: $(OBJDIR)/$(PROJ_NAME).elf
	$(GDB) --tui $(OBJDIR)/$(PROJ_NAME).elf -ex "target remote :3333"

# Dependdencies
$(OBJDIR)/$(PROJ_NAME).elf: $(FWLIB) $(OBJS) | $(OBJDIR)


TAGFILES    := $(OBJS:.o=.t)

%.t: %.d
	@(cat $< 2>/dev/null || true) | sed 's/.*://' | tr -d '\\' | tr "\n" " " | (xargs -n 1 readlink -f > $@ 2>/dev/null || true)

%.d: %.o
	@echo >/dev/null	#do nothing, specify dependency only

-include $($(OBJS:.o=.d))

tags: $(TAGFILES)
	@(cat $(TAGFILES) 2>/dev/null || true) | sort | uniq | xargs etags
