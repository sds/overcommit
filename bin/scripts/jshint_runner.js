/**
 * @author kamil@causes.com
 *
 * This is a script to run jshint against files passed in via
 * command line arguments
 **/

if (typeof JSHINT === "undefined") {
  print("jshint not available. Make sure it was included properly.");
  quit();
}

// Options:
// https://gist.github.com/1489652

var i, j, file, source, result, error,
  options = {
    boss:   true,
    curly:  true,
    eqeqeq: true,
    forin:  true,
    newcap: true
  };

for (i = 0; i < arguments.length; i++) {

  file = arguments[i];
  source = readFile(file);
  result = JSHINT(source, options);

  if (!result) {
    for (j = 0; j < JSHINT.errors.length; j++) {
      error = JSHINT.errors[j];

      print(file + ": line " + error.line + ", col  " + error.character + ", " +
            error.reason);
      print("\t" + error.evidence);
    }
  }
}


