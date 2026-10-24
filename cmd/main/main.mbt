///|
fn main {
  let all_args = @env.args()
  let args = if all_args.is_empty() { [] } else { all_args[1:].to_owned() }
  let result = @readability.run_cli_args(args, fn(path) {
    try {
      Some(@fs.read_file_to_string(path))
    } catch {
      _ => None
    }
  })
  if result.stdout != "" {
    println(result.stdout.trim_end(chars="\n").to_owned())
  }
  if result.stderr != "" {
    println(result.stderr.trim_end(chars="\n").to_owned())
  }
  if result.exit_code != 0 {
    @sys.exit(1)
  }
}
