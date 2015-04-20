module.exports = Errors = (require "error-doc").create()
    .define("AlreadyDone")
    .define("AlreadyExcuting")
    .define("TaskFailed")
    .generate