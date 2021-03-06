# read_spss

# based on read.spss, only change is in the suppressWarnings for
# unknown file types (which is harmless)

read_spss <- function (file, use.value.labels = TRUE, to.data.frame = FALSE,
    max.value.labels = Inf, trim.factor.names = FALSE, trim_values = TRUE,
    reencode = NA, use.missings = to.data.frame)
{
    trim <- function(strings, trim = TRUE) if (trim)
        sub(" +$", "", strings)
    else strings
    knownCP <- c(`UCS-2LE` = 1200, `UCS-2BE` = 1201, macroman = 10000,
        ` UCS-4LE` = 12000, `UCS-4BE` = 12001, `koi8-r` = 20866,
        `koi8-u` = 21866, latin1 = 28591, latin2 = 28592, latin3 = 28593,
        latin4 = 28594, `latin-9` = 28605, `ISO-2022-JP` = 50221,
        `euc-jp` = 51932, `UTF-8` = 65001, ASCII = 20127, CP1250 = 1250,
        CP1251 = 1251, CP1252 = 1252, CP1253 = 1253, CP1254 = 1254,
        CP1255 = 1255, CP1256 = 1256, CP1257 = 1257, CP1258 = 1258,
        CP874 = 874, CP936 = 936)
    if (length(grep("^(http|ftp|https)://", file))) {
        tmp <- tempfile()
        download.file(file, tmp, quiet = TRUE, mode = "wb")
        file <- tmp
        on.exit(unlink(file))
    }
    suppressWarnings(rval <- .Call(foreign:::do_read_SPSS, file))
    codepage <- attr(rval, "codepage")
    if (is.null(codepage))
        codepage <- 2
    if (!capabilities("iconv"))
        reencode <- FALSE
    if (!identical(reencode, FALSE)) {
        cp <- "unknown"
        if (is.character(reencode)) {
            cp <- reencode
            reencode <- TRUE
        }
        else if (codepage == 20127) {
            reencode <- FALSE
        }
        else if (m <- match(codepage, knownCP, 0L)) {
            cp <- names(knownCP)[m]
        }
        else if (codepage < 200) {
            attr(rval, "codepage") <- NULL
            reencode <- FALSE
        }
        else cp <- paste("CP", codepage, sep = "")
        if (is.na(reencode))
            reencode <- l10n_info()[["UTF-8"]]
        if (reencode) {
            #message(gettextf("re-encoding from %s", cp), domain = NA)
            names(rval) <- iconv(names(rval), cp, "")
            vl <- attr(rval, "variable.labels")
            nm <- names(vl)
            vl <- iconv(vl, cp, "")
            names(vl) <- iconv(nm, cp, "")
            attr(rval, "variable.labels") <- vl
            for (i in seq_along(rval)) {
                xi <- rval[[i]]
                if (is.character(xi))
                  rval[[i]] <- iconv(xi, cp, "")
            }
        }
    }
    miss <- attr(rval, "missings")
    if (!is.null(miss)) {
        if (reencode) {
            nm <- names(miss)
            names(miss) <- iconv(nm, cp, "")
            for (i in seq_along(miss)) if (is.character(miss[[i]]$value))
                miss[[i]]$value <- iconv(miss[[i]]$value, cp,
                  "")
            attr(rval, "missings") <- miss
        }
        if (use.missings)
            for (v in names(rval)) {
                tp <- miss[[v]]$type
                if (tp %in% "none")
                  next
                if (tp %in% c("one", "two", "three")) {
                  xi <- rval[[v]]
                  other <- miss[[v]]$value
                  xi[xi %in% other] <- NA
                  rval[[v]] <- xi
                }
                else if (tp == "low" || tp == "low+1") {
                  xi <- rval[[v]]
                  z <- miss[[v]]$value
                  if (tp == "low+1")
                    xi[xi <= z[1L] | xi == z[2L]] <- NA
                  else xi[xi <= z[1L]] <- NA
                  rval[[v]] <- xi
                }
                else if (tp == "high" || tp == "high+1") {
                  xi <- rval[[v]]
                  z <- miss[[v]]$value
                  if (tp == "high+1")
                    xi[xi >= z[1L] | xi == z[2L]] <- NA
                  else xi[xi >= z[1L]] <- NA
                  rval[[v]] <- xi
                }
                else if (tp == "range" || tp == "range+1") {
                  xi <- rval[[v]]
                  z <- miss[[v]]$value
                  if (tp == "range+1")
                    xi[xi >= z[1L] | xi <= z[2L] | xi[xi == z[3L]]] <- NA
                  else xi[xi >= z[1L] | xi <= z[2L]] <- NA
                  rval[[v]] <- xi
                }
                else warning(gettextf("missingness type %s is not handled",
                  tp), domain = NA)
            }
    }
    else use.missings <- FALSE
    vl <- attr(rval, "label.table")
    if (reencode)
        names(vl) <- iconv(names(vl), cp, "")
    has.vl <- which(!sapply(vl, is.null))
    for (v in has.vl) {
        nm <- names(vl)[[v]]
        nvalues <- length(na.omit(unique(rval[[nm]])))
        nlabels <- length(vl[[v]])
        if (reencode && nlabels) {
            nm2 <- names(vl[[v]])
            vl[[v]] <- iconv(vl[[v]], cp, "")
            names(vl[[v]]) <- iconv(nm2, cp, "")
        }
        if (use.missings && !is.null(mv <- miss[[v]]$value))
            vl[[v]] <- vl[[v]][!vl[[v]] %in% mv]
        if (use.value.labels && (!is.finite(max.value.labels) ||
            nvalues <= max.value.labels) && nlabels >= nvalues) {
            rval[[nm]] <- factor(trim(rval[[nm]], trim_values),
                levels = rev(trim(vl[[v]], trim_values)), labels = rev(trim(names(vl[[v]]),
                  trim.factor.names)))
        }
        else attr(rval[[nm]], "value.labels") <- vl[[v]]
    }
    if (reencode)
        attr(rval, "label.table") <- vl
    if (to.data.frame) {
        varlab <- attr(rval, "variable.labels")
        rval <- as.data.frame(rval)
        attr(rval, "variable.labels") <- varlab
        if (codepage > 500)
            attr(rval, "codepage") <- codepage
    }
    rval
}
