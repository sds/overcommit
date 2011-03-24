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

var i, j, file, source, result, error,
  options = {
    boss:    true,
    curly:   true,
    eqeqeq:  true,
    forin:   true,
    newcap:  true,
  };

for (i = 0; i < arguments.length; i++) {

  file = arguments[i];
  source = readFile(file);
  result = JSHINT(source, options);

  if (result === true) {
    print(arguments[i] + " -- OK");
  }
  else {
    for (j = 0; j < JSHINT.errors.length; j++) {
      error = JSHINT.errors[j];

      print("ERROR in " + file + " at " + error.line + ":" + error.character);
      print("");
      print("\t" + error.reason);
      print("");
      print("\t" + error.evidence);
      print("");
    }
  }
}


