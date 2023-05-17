
# Precompilation routines 
PrecompileTools.@setup_workload begin
    PrecompileTools.@compile_workload begin

        # Precompile Epochs routines for all time scales 
        for scale in Tempo.TIMESCALES_ACRONYMS
            epo = Epoch("2022-02-12T12:00:34.3241 $scale")
            j2000(epo)
            j2000s(epo)
            j2000c(epo)
        end

        # Precompile timescale offset functions 
        for fcn in (
            offset_gps2tai,
            offset_tai2gps,
            offset_tt2tdbh,
            offset_utc2tai,
            offset_tai2utc,
            offset_tdb2tt,
            offset_tt2tdb,
            offset_tdb2tcb,
            offset_tcb2tdb,
            offset_tt2tcg,
            offset_tcg2tt,
            offset_tt2tai,
            offset_tai2tt,
        )
            fcn(200.0)
        end

        # Precompile datetime stuff 
        Date(23)
        DateTime("2022-02-12T12:00:32")
        DateTime(21321.034)

        date = Date(2022, 12)
        dt = DateTime(date, 2312.04)

        Date(dt)
        Time(dt)

        for fcn in (year, month, day, hour, minute, second)
            fcn(dt)
        end

        # Precompile smaller routines
        tai2utc(DJ2000, 0.0)
        utc2tai(DJ2000, 0.0)
        jd2calhms(DJ2000, 0.0)
        fd2hmsf(0.4)
    end
end
