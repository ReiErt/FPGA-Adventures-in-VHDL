import numpy as np
import matplotlib.pyplot as plt
import math

# Block Ram can hold up to 32 Kilo bit / 16 bit = 2000 addresses/samples.
fs = 4096 # sample rate
f = 2

# Generating array in x from 0 to fs
x = np.arange(fs)

# Plot amplitude at each sample.
# Use first constant value to plot the size of sine. In this project, we plot only the first fourth
y = np.sin((1/4)* np.pi*f * (x/fs))

# write following to created file
file1 = open("MyFile.txt", "w")
file1.write("// memory data file (do not edit the following line - required for mem load use)\n")
file1.write("// instance=/ram_tb/dpram1/mem\n")
file1.write("// format=mti addressradix=d dataradix=d version=1.0 wordsperline=1\n")

# ------------------- CREATE LOGIC THAT TURNS Y VALUE INTO 16 BIT SIGNED IN FIXED POINT -- BEGIN ----------------
number = 0
#interate through fs and print in each item
for item in range (fs):
    file1.write(str(number))
    file1.write(": ")
    number = number + 1
    # Floating point arithmetic * 10000
    power = math.pow(2,15)
    this_y = y[item] * power
    # Convert floating point to int. Decimal part falls off
    int_y_array    = this_y.astype(int)
    hexValue = hex(int_y_array)
    stringHex = str(hexValue)
    correct_stringHex = stringHex[2:]
# ------------------- CREATE LOGIC THAT TURNS Y VALUE INTO 16 BIT SIGNED IN FIXED POINT -- END ----------------


# --------------------- WRITE TO FILE -- BEGIN ----------------
# fyi: OUTPUT MUST BE A STRING
    while (len(correct_stringHex) < 4):
        correct_stringHex = "0" + correct_stringHex
    file1.write(correct_stringHex)
    file1.write("\n")
file1.close()
# --------------------- WRITE TO FILE -- END ----------------


# ------------------------ PLOT GRAPH -- BEGIN ------------------------
# Plotting time vs amplitude using plot function from pyplot
plt.plot(x, y)

# Settng title for the plot in blue color
plt.title('Single period sine wave', color='b')

# Setting x axis label for the plot
plt.xlabel('Sample specifying the address in block ram')

# Setting y axis label for the plot
plt.ylabel('Amplitude value stored in block ram')

# Showing grid
plt.grid()

# Highlighting axis at x=0 and y=0
plt.axhline(y=0, color='k')
plt.axvline(x=0, color='k')

# shows exact location of samples
plt.stem(x,y, 'r')
plt.plot(x,y)

# Finally displaying the plot
plt.show()
# ------------------------ PLOT GRAPH -- END --------------------------