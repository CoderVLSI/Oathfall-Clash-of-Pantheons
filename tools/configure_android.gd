@tool
extends SceneTree

func _initialize() -> void:
 var settings := EditorInterface.get_editor_settings()
 settings.set_setting("export/android/android_sdk_path",OS.get_environment("ANDROID_HOME"))
 settings.set_setting("export/android/java_sdk_path",OS.get_environment("JAVA_HOME"))
 var error := ResourceSaver.save(settings)
 if error != OK:
  printerr("Failed to save Android SDK settings: ",error)
  quit(1)
 else:
  print("Android SDK and Java configured.")
  quit(0)

