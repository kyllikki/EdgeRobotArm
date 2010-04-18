[CCode(cheader_filename = "libedgerbtarm.h",
	   lower_case_cprefix = "edgerbtarm_", cprefix = "")]
namespace edgerbtarm {

    [CCode(cprefix = "motor_", has_type_id = false)]
	public enum motor_dir {
        off,
        forward,
        back,
        brake
	}

    public int init();
    public int close();

    public void stop_arm();
    public void ctrl_motor(int motorn, motor_dir direction);

}
