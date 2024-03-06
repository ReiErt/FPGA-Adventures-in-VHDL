import numpy as np
import matplotlib.pyplot as plt
import math

# With 16 bits of data in each address, a Block Ram holds 2048 addresses.
# Vivado automatically pads with 0s. That means if 1 address of RAM is used, the rest is padded with 0.

#### IMPORTANT #####
# Input sample rate per period
fs = 4096

# Generating array in x from 0 to fs
x = np.arange(fs)

# Equation to calculate first fourth of sine wave
f = 2
y = np.sin((1/4) * np.pi*f * (x/fs))

# write following to created file
file1 = open("MyFile.txt", "w")


# ------------------- CREATE LOGIC THAT TURNS Y VALUE INTO 16 BIT SIGNED IN FIXED POINT -- BEGIN ----------------
count = 0
count_character_in_row = 1
count_row_space = 1
#file1.write("@00000\n")

#interate through fs and print in each item
for item in range (fs):
    # Floating point arithmetic * 10000
    power = math.pow(2,15)
    this_y = y[item] * power
    # Convert floating point to int. Decimal part falls off
    int_y_array    = this_y.astype(int)
# ------------------- CREATE LOGIC THAT TURNS Y VALUE INTO 16 BIT SIGNED IN FIXED POINT -- END ----------------


# --------------------- WRITE TO FILE -- BEGIN ----------------
    hexValue = hex(int_y_array)[2:]
    result_string = str(hexValue)
    print(result_string)
    while (len(result_string) < 4):
        result_string = "0" + result_string
    file1.write(result_string)
    file1.write("\n")

    count = count + 1
file1.close()
# --------------------- WRITE TO FILE -- END ----------------


# ------------------------ PLOT GRAPH -- BEGIN ------------------------
plt.plot(x, y)
plt.title('Sine Wave', color='b')
plt.xlabel('Sample(s)')
plt.ylabel('Sin(x) '+ r'$\rightarrow$')
plt.grid()
plt.axhline(y=0, color='k')
plt.axvline(x=0, color='k')
plt.stem(x,y, 'r')
plt.plot(x,y)
plt.show()
# ------------------------ PLOT GRAPH -- END --------------------------