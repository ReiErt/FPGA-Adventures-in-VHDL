# this script sends ascii data from COM port to FPGA. Hopefully, FPGA will "echo" or return all characters.
import time
import serial
from serial import Serial

# configure the serial connections (the parameters differs on the device you are connecting to)
serialPort = serial.Serial(
    port="COM9",
    baudrate=115200,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    xonxoff=0,
    rtscts=0,
    bytesize=8,
    timeout =10
)

# following text is 3000 ascii characters long
serialPort.write(b"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Sed viverra ipsum nunc aliquet. Ullamcorper sit amet risus nullam eget felis eget. Accumsan lacus vel facilisis volutpat est velit egestas dui. Nam aliquam sem et tortor consequat id porta nibh venenatis. Lobortis feugiat vivamus at augue eget arcu dictum varius duis. Neque sodales ut etiam sit. Nulla posuere sollicitudin aliquam ultrices sagittis orci a. Lectus vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt ornare. Etiam dignissim diam quis enim lobortis scelerisque fermentum dui faucibus. Est ullamcorper eget nulla facilisi etiam. Neque gravida in fermentum et sollicitudin.Amet consectetur adipiscing elit pellentesque habitant. Sed lectus vestibulum mattis ullamcorper velit. Nascetur ridiculus mus mauris vitae ultricies. Dui sapien eget mi proin sed. Tortor at auctor urna nunc id cursus metus aliquam. Ut eu sem integer vitae justo eget magna fermentum. Vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt. Enim sed faucibus turpis in. Amet justo donec enim diam vulputate ut pharetra sit amet. Ultrices in iaculis nunc sed augue lacus viverra. Fermentum posuere urna nec tincidunt praesent. Ut placerat orci nulla pellentesque dignissim enim sit. Pulvinar pellentesque habitant morbi tristique senectus et. Viverra tellus in hac habitasse platea dictumst vestibulum rhoncus. Consequat interdum varius sit amet mattis vulputate enim nulla. Tincidunt vitae semper quis lectus nulla at.Mauris pharetra et ultrices neque ornare aenean euismod elementum nisi. Vel quam elementum pulvinar etiam non quam. Ut etiam sit amet nisl purus in mollis nunc. Malesuada fames ac turpis egestas. Eu volutpat odio facilisis mauris sit amet massa vitae tortor. Aenean sed adipiscing diam donec adipiscing tristique risus nec feugiat. Pulvinar mattis nunc sed blandit. Viverra nibh cras pulvinar mattis nunc sed blandit. Sit amet nulla facilisi morbi tempus iaculis urna id volutpat. Lobortis mattis aliquam faucibus purus in massa. Amet consectetur adipiscing elit pellentesque habitant morbi tristique senectus. Nibh tortor id aliquet lectus proin.Morbi leo urna molestie at elementum eu. Blandit massa enim nec dui nunc. Neque sodales ut etiam sit. Lorem mollis aliquam ut porttitor leo a diam. Semper auctor neque vitae tempus. Quis risus sed vulputate odio ut enim blandit. Lorem mollis aliquam ut porttitor. Viverra accumsan in nisl nisi scelerisque eu. Molestie ac feugiat sed lectus vestibulum mattis ullamcorper velit sed. Ultrices gravida dictum fusce ut placerat orci nulla pellentesque dignissim. Nunc pulvinar sapien et ligula ullamcorper malesuada. Mauris nunc congue nisi vitae suscipit tellus mauris a. Augue mauris augue neque gravida in fermentum et sollicitudin ac. Urna id volutpat lacus laoreet non curabitur. Non nisi est sit amet facilisis magna etiam tempor orci. Ac felis donec et odio.Semper risus in hendrerit gravida rutrum quisque non. Odio morbi quis commodo odio aenean sed adipiscing. Turpis tincidunt id aliquet risus. Non pulvinar neque laoreet suspendisse interdum consectetur libero id faucibus. Quis lectus nulla at volutpat diam ut. Mi sit amet mauris commodo quis imperdiet. Dignissim suspendisse in est ante in. Vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt ornare massa. Nunc sed id semper risus in hendrerit gravida rutrum. Dolor sit amet consectetur adipiscing elit ut aliquam purus sit. Netus et malesuada fames ac turpis egestas maecenas. At augue eget arcu dictum varius duis. Dui id ornare arcu odio ut sem nulla pharetra diam. Quis risus sed vulputate odio ut enim. Sit amet purus gravida quis blandit turpis cursus in hac.")
serialString = ""

while 1 :
    if serialPort.in_waiting > 0:
        serialPort.write(b"This is a test text to demostrate that the UART works without issue at 115200")
        serialString = serialPort.readline(60)

        try:
            print("the text is")
            print(serialString)
            #print(serialString.decode('ascii'))

        except:
            print("error")