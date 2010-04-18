/* libedgerbtarm.c
 *
 * Edge USB robotic arm, trivial control library
 *
 * Copyrigt 2010 Vincent Sanders <vince@kyllikki.org>
 *
 * Released under the MIT licence.
 */

/* compile with something like
 *
 * gcc -Wall -I/usr/include/libusb-1.0/ -lusb-1.0 --shared -fPIC -o libedgerbtarm.so libedgerbtarm.c
 *
 */

#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>
#include <malloc.h>

#include <libusb.h>

#include "libedgerbtarm.h"

static libusb_device_handle *handle;
static motor_dir *motors;
static bool led = false;

static bool 
is_interesting(libusb_device *device)
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


/** Turn everything off */
static void
stop_arm(libusb_device_handle *handle)
{
    uint8_t buf[4];

    buf[0] = 0;
    buf[1] = 0;
    buf[2] = 0;

    libusb_control_transfer(handle, LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE, 6, 0x100, 0, buf, 3, 0);

}

static void
control_arm(libusb_device_handle *handle, 
                       motor_dir *motors, 
                       bool led)
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


void
edgerbtarm_ctrl_motor(int motorn, motor_dir direction)
{
    if ((motorn >= 0) && (motorn <= 5)) { 
        motors[motorn] = direction;
    } else if (motorn == -1) {
        if (direction == motor_forward) {
            led = true;
        } else if (direction == motor_back) {
            led = false;
        }    
    } else {
        return; /* bad motor number */
    }
    
    control_arm(handle, motors, led); 
}

void
edgerbtarm_stop_arm(void)
{
    stop_arm(handle);
}

int
edgerbtarm_init(void)
{

    libusb_device **list;
    ssize_t cnt;
    ssize_t i = 0;
    int err = 1;

    motors = calloc(5, sizeof(motor_dir));

    libusb_init(NULL);

    libusb_set_debug(NULL, 3);

    cnt = libusb_get_device_list(NULL, &list);

    if (cnt < 0) {
        libusb_exit(NULL);
        return -1;
    }

    /* discover devices */
    for (i = 0; i < cnt; i++) {
        libusb_device *device = list[i];
        if (is_interesting(device)) {
            err = libusb_open(device, &handle);
            break;
        }
    }

    libusb_free_device_list(list, 1);

    if (err) {
        libusb_exit(NULL);
        return -1;
    } 

    return 0;
}


int
edgerbtarm_close(void)
{
    stop_arm(handle); /* shut it all off */

    libusb_close(handle);

    libusb_exit(NULL);

    return 0;
}
