# Test4z

## How Test4z was added to original doggos-gse

1. `t4z init` executed at the repository root

3. `test4z.project.config.json` has been modified to reflect the structure of the project:

    ```json
    {
        "appLoadLibraries": ["PLAPE03.PUBLIC.LOADLIB"],
        "bindSyslibs": ["CEE.SCEELKED"],
        "copyPaths": ["DOGGOS/COPY/*.CPY"],
        "cobolTestGlobs": ["DOGGOS/COBTEST/*.cbl"]
    }
    ```

    *Notes:*

    - `appLoadLibraries` is set to the loadlib that is created by Doggos Team Build process (`syncz -c bldz`), in my case `[PLAPE03.PUBLIC.LOADLIB]`
    - latest develop build is required to support `"copyPaths": ["DOGGOS/COPY/*.CPY"],`
    - I have chosen element type `COBTEST` for our ZTTDOGOS.cbl test suite and copied our [ZTTDOGOS.cbl](https://github.gwd.broadcom.net/MFD/test4z-link/blob/main/cobol_api/test/ZTTDOGOS.cbl) to `DOGGOS/COBTEST`

4. Modify ZTTDOGOS.cbl to use copybooks DOGGOS/COPY - line 83:

    ```cobol
    COPY ADOPTRPT.
    ```

5. Make program reentrant and use TEST compile option in DOGGOS/COBOL/BUILDZ.js:

    ```js
    var generated = compile.cobol({
        srcs: "*.CBL",
        copyPaths: [`//'${os.user()}.DOGGOS.COPYBOOK'`],
        opts: [
            "APOST",
            "LIST",
            "RENT",
            "MAP",
            "NONUMBER",
            "XREF",
            "TEST", // <=== Required by Test4z
            "NOSTGOPT",
            "OPT(0)",
            "LINECOUNT(60)",
        ],
    });

    // Bind the objects into an executable

    var binderGenerated = binder.bind({
        outs: "doggos",
        syslibs: ["//CEE.SCEELKED"],
        deps: generated.rules,
        opts: ["XREF", "LIST", "LET", "MAP", "REUS(RENT)", "AMODE=31", "RMODE=ANY"], // <=== REUS(RENT) required by Test4z
    });
    ```

6. Tests can be executed by `t4z` at the root level
