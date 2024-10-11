package com.runtimeverification.rvmonitor.java.rvj.output;

import com.runtimeverification.rvmonitor.java.rvj.Main;
import com.runtimeverification.rvmonitor.java.rvj.parser.ast.PackageDeclaration;

public class Util {

    public static String getDefaultLocation() {
        if (Main.options.locationFromAjc) {
            return  "com.runtimeverification.rvmonitor.java.rt.ViolationRecorder.getLineOfCode("
                    + "joinpoint)";
        } else {
            return  "com.runtimeverification.rvmonitor.java.rt.ViolationRecorder.getLineOfCode()";
        }
    }

    public static String packageAndNameToUrl(
            PackageDeclaration packageDeclaration, String name) {
        return "https://github.com/SoftEngResearch/tracemop/tree/master/scripts/props/"
                + name
                + ".mop";
    }
}
