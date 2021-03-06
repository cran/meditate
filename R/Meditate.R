#' Run Meditation Timer
#'
#' A simple meditation timer that logs session information.
#'
#' @param duration 'numeric' number.
#'   Meditation time in minutes.
#' @param interval 'numeric' number.
#'   Interval time in minutes.
#' @param repeats 'logical' flag.
#'   Whether to repeat the time interval.
#' @param sound 'logical' flag.
#'   Whether to include a start, end, and interval sound.
#'   Requires access to an \link[audio:audio.drivers]{audio driver}.
#' @param preparation 'numeric' number.
#'   Preparation time in seconds.
#' @param file 'character' string or '\link[base:connections]{connection}'.
#'   File to write session information---new data records
#'   will be appended to this comma-separated values (CSV) file.
#'   A data record consists of a session's start time in
#'   Coordinated Universal Time (UTC) and duration in minutes.
#' @param mandala 'logical' flag.
#'   Whether to plot a mandala.
#' @param ...
#'   Arguments passed to the \code{\link{PlotMandala}} function.
#' @param user_stops 'logical' flag.
#'   Whether to manually stop the session timer.
#'   Allows for extended meditation.
#'
#' @return Invisible \code{NULL}
#'
#' @author J.C. Fisher
#'
#' @seealso
#'   \code{\link{ReadSessions}} function to read and summarize the
#'   exported session information back into \R.
#'
#' @keywords misc
#'
#' @export
#'
#' @examples
#' meditate::Meditate(0.1, sound = FALSE, preparation = NULL, file = NULL)
#'
#' \dontrun{
#' # Begin a 10-minute meditation session with mandala:
#' meditate::Meditate(10, mandala = TRUE)
#' }
#'

Meditate <- function(duration=20, interval=NULL, repeats=TRUE,
                     sound=TRUE, preparation=10, file="meditate.csv",
                     mandala=FALSE, ..., user_stops=FALSE) {

  # if copy-pasting, run the following command:
  # lazyLoad(file.path(system.file("R", package="meditate"), "sysdata"))

  # check arguments
  checkmate::assertNumber(duration, lower=0, finite=TRUE)
  checkmate::assertNumber(interval, lower=0, finite=TRUE, null.ok=TRUE)
  checkmate::assertFlag(repeats)
  checkmate::assertFlag(sound)
  checkmate::assertNumber(preparation, lower=0, finite=TRUE, null.ok=TRUE)
  if (!is.null(file))
    checkmate::assertPathForOutput(file, overwrite=TRUE, extension="csv")
  checkmate::assertFlag(mandala)
  checkmate::assertFlag(user_stops)

  if (mandala) {
    PlotMandala(...)
    Sys.sleep(1)
  }

  if (!is.null(preparation) && preparation > 0) {
    cat("Prepare\n")
    utils::flush.console()
    Sys.sleep(preparation)
  }

  if (sound & any(audio::audio.drivers()$current))
    ring <- audio::play(sounds[["bowl struck"]])
  else
    ring <- NULL

  cat("Start\n")
  utils::flush.console()

  stime <- Sys.time()
  etime <- stime + duration * 60

  on.exit(.End(stime, etime, file))

  if (is.null(interval) || interval == 0) {
    intervals <- as.character()
  } else {
    intervals <- seq(stime, etime, by=interval * 60)
    intervals <- intervals[intervals > stime & intervals < etime]
    if (!repeats && length(intervals) > 0) intervals <- intervals[1]
  }

  while (TRUE) {
    Sys.sleep(1)
    sys_time <- Sys.time()

    if (sys_time >= etime) {

      cat("End\n")
      utils::flush.console()

      if (!is.null(ring)) {
        audio::pause(ring)
        audio::rewind(ring)
        audio::resume(ring)
      }

      if (user_stops) invisible(readline("Press [enter] to stop timer "))

      return(invisible())
    }

    if (length(intervals) > 0 && sys_time >= intervals[1]) {
      cat("Interval\n")
      utils::flush.console()
      audio::wait(audio::play(sounds[["bell kyoto"]]))
      intervals <- intervals[-1]
    }

  }
}


# function to run at end of session

.End <- function(stime, etime, file) {

  sys_time <- Sys.time()
  duration <- as.numeric(sys_time - stime, units="mins")
  premature <- sys_time < etime

  if (premature) {
    cat("Premature\n")
    utils::flush.console()
  }

  if (!is.null(file)) {

    if (premature) {
      ans <- if (interactive()) readline("Save? [y/N]: ") else "n"
      if (tolower(substr(ans, 1, 1)) != "y") return(invisible())
    }

    if (!checkmate::testFileExists(file))
      cat("start_time,duration", file=file, fill=TRUE)
    cat(format(stime, tz="UTC"), format(round(duration, 1), nsmall=1),
        file=file, sep=",", fill=TRUE, append=TRUE)
  }

}
