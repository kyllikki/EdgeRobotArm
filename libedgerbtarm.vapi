[CCode(cheader_filename = "libedgerbtarm.h",
	   lower_case_cprefix = "edgerbtarm_", cprefix = "")]
namespace edgerbtarm {
public int init();
public int close();

public void stop_arm();
public void ctrl_motor(int motorn, bool on, bool fwd);

}