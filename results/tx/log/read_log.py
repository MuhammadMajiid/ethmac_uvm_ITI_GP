import sys

MARKER = "# UVM_INFO repo/tb/virtual_seq_sqr/eth_v_seq_tx.sv(34)"
KEYWORDS = (
    "[TX_CONFIG]",
    "UVM_ERROR",
    "UVM_WARNING",
)

def parse_log(filename, output_filename):
    printing_section = False
    with open(filename, "r", errors="ignore") as f:
        with open(output_filename, "w") as out:
            for line in f:
                line = line.rstrip()
                # Start of a new section
                if line.startswith(MARKER):
                    if printing_section:
                        out.write("\n")  # Blank line between sections
                    printing_section = True
                    out.write(line + "\n")
                    continue
                # Write matching lines within the current section
                if printing_section and any(keyword in line for keyword in KEYWORDS):
                    out.write(line + "\n")

if __name__ == "__main__":
    parse_log("D:/C/ITI/GP/repo/results/tx/log/eth_test_tx_moder.log","D:/C/ITI/GP/repo/results/tx/log/eth_test_tx_moder_errors.txt")