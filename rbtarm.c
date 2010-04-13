/* rbtarm.c
 *
 * Maplin cheap robotic arm, trivial control software
 *
 * Copyrigt 2010 Vincent Sanders <vince@kyllikki.org>
 *
 * Released under the MIT licence.
 */

/* compile with something like
 *
 * gcc -I/usr/include/libusb-1.0/ -lusb-1.0 -o rbtarm rbtarm.c
 *
 */

#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>
#include <malloc.h>

#include <libusb.h>

bool is_interesting(libusb_device *device)
{
    struct libusb_device_descriptor desc;
    int r = libusb_get_device_descriptor(device, &desc);
    if (r < 0) {
        fprintf(stderr, "failed to get device descriptor");
        return false;
    }

    if ((desc.idVendor == 0x1267) && (desc.idProduct == 0x0))
        return true;

    return false;
}

typedef enum motor_dir_e {
    motor_off = 0,
    motor_forward = 1,
    motor_back = 2,
} motor_dir_t;

/** Turn everything off */
void
stop_arm(libusb_device_handle *handle)
{
    uint8_t buf[4];

    buf[0] = 0;
    buf[1] = 0;
    buf[2] = 0;

    libusb_control_transfer(handle, LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE, 6, 0x100, 0, buf, 3, 0);

}

void
control_arm(libusb_device_handle *handle, motor_dir_t *motors, bool led)
{
    uint32_t ctrl = 0;
    uint8_t buf[4];
    int motor_loop;

    if (led)
        ctrl |= 0xff<<16;

    for (motor_loop = 0; motor_loop < 5; motor_loop++) {
        //printf("%s: motors[%d]=%x\n",__func__,motor_loop, motors[motor_loop]);
        ctrl |= (motors[motor_loop] << (motor_loop<<1));
    }

    buf[0] = ctrl & 0xff;
    buf[1] = (ctrl & 0xff00) >> 8;
    buf[2] = (ctrl & 0xff0000) >> 16;

    //printf("%s: ctrl is %x buf %x,%x,%x\n",__func__,ctrl,buf[0],buf[1],buf[2]);

    libusb_control_transfer(handle, LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE, 6, 0x100, 0, buf, 3, 0);

}

/* motor to test run forwards and back (remember folks its 0 based so whats
 * labeled M1 is motor 0
 */
#define TEST_MOTOR 0

int
main(int argc, char **argv)
{
    motor_dir_t *motors;

    motors = calloc(5, sizeof(motor_dir_t));

    libusb_init(NULL);

    libusb_set_debug(NULL,3);

    // discover devices
    libusb_device **list;
    libusb_device *found = NULL;
    ssize_t cnt = libusb_get_device_list(NULL, &list);
    ssize_t i = 0;
    int err = 0;
    if (cnt < 0)
        error();

    for (i = 0; i < cnt; i++) {
        libusb_device *device = list[i];
        if (is_interesting(device)) {
            found = device;
            break;
        }
    }

    if (found) {
        libusb_device_handle *handle;
        unsigned char state[10];

        err = libusb_open(found, &handle);
        if (err) {
            //error();
        } else {


            control_arm(handle, motors, true); /* LED go on */
            sleep(1);
            control_arm(handle, motors, false); /* LED go off */

            motors[TEST_MOTOR] = motor_forward;
            control_arm(handle, motors, false); /* motor forward */
            sleep(2);

            motors[TEST_MOTOR] = motor_back;
            control_arm(handle, motors, false); /* motor backward */
            sleep(2);

            stop_arm(handle); /* shut it all off */

            libusb_close(handle);
        }
    }

    libusb_free_device_list(list, 1);

    libusb_exit(NULL);

    return 0;
}
