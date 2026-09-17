var xcode = require('xcode');
var fs = require('fs');
var path = require('path');

var projectPath = path.resolve(__dirname, '../ios/Runner.xcodeproj/project.pbxproj');
var myProj = xcode.project(projectPath);

myProj.parse(function (err) {
    if (err) {
        console.error("Error parsing:", err);
        process.exit(1);
    }
    
    // find the Runner group key
    var groups = myProj.hash.project.objects['PBXGroup'];
    var runnerGroupKey = null;
    for (var key in groups) {
        if (!key.endsWith('_comment')) {
            var group = groups[key];
            if (group.name === 'Runner' || group.path === 'Runner') {
                runnerGroupKey = key;
                break;
            }
        }
    }
    
    // Add the file to the project
    var options = { target: myProj.getFirstTarget().uuid };
    var file = myProj.addSourceFile('GlassesPlatformHandler.swift', options, runnerGroupKey);
    
    if (!file) {
        console.log("File could not be added.");
    } else {
        console.log("Added GlassesPlatformHandler.swift successfully.");
        fs.writeFileSync(projectPath, myProj.writeSync());
    }
});
