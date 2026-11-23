transcript on

echo "=============================================="
echo "        APB UVM VERIFICATION PROJECT"
echo "=============================================="

echo "Cleaning work library..."

if {[file exists work]} {
    vdel -all
}

vlib work


echo "Compiling APB UVM testbench..."

vlog -sv testbench.sv


echo "Compilation completed."


echo "Starting simulation..."

vsim -voptargs=+acc work.test


echo "Adding APB waveform signals..."

add wave sim:/test/pclk
add wave sim:/test/apb_vif/*


echo "Running simulation..."

run -all


echo "=============================================="
echo "        APB SIMULATION COMPLETED"
echo "=============================================="