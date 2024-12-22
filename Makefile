IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

RTL_DIR = rtl
TB_DIR = tb
SIM_DIR = sim

RTL_SRCS = $(RTL_DIR)/core/nash_core.v $(RTL_DIR)/core/nash_top.v
TB_SRCS = $(TB_DIR)/nash_tb.v

SIM_TARGET = $(SIM_DIR)/nash_tb.vvp
WAVE_FILE = nash_tb.vcd

.PHONY: all clean sim wave

all: sim

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(SIM_TARGET): $(RTL_SRCS) $(TB_SRCS) | $(SIM_DIR)
	$(IVERILOG) -o $@ -I$(RTL_DIR)/core $^

sim: $(SIM_TARGET)
	$(VVP) $<

wave: $(WAVE_FILE)
	$(GTKWAVE) $< &

clean:
	rm -rf $(SIM_DIR)
	rm -f $(WAVE_FILE)