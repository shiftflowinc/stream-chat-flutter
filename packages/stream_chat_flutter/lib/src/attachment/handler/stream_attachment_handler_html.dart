import 'package:file_picker/file_picker.dart';
import 'package:stream_chat_flutter/src/attachment/handler/common.dart';
import 'package:stream_chat_flutter/src/attachment/handler/stream_attachment_handler_base.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// StreamAttachmentHandler implementation for html.
class StreamAttachmentHandler extends StreamAttachmentHandlerBase {
  StreamAttachmentHandler._();

  static StreamAttachmentHandler? _instance;

  /// Returns the singleton instance of [StreamAttachmentHandler].
  // ignore: prefer_constructors_over_static_methods
  static StreamAttachmentHandler get instance =>
      _instance ??= StreamAttachmentHandler._();

  @override
  Future<Attachment?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = true,
  }) async {
    final result = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      windowsOptions: WindowsOptions(lockParentWindow: lockParentWindow),
      linuxOptions: LinuxOptions(lockParentWindow: lockParentWindow),
    );

    return result?.toAttachment(
      type: type.toAttachmentType(),
      withData: withData,
    );
  }

  @override
  Future<String?> downloadAttachment(
    Attachment attachment, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final data = await downloadAttachmentData(
      attachment,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );

    // Create an XFile for proper file saving.
    final file = data.toXFile();

    // Save the file. We are not using the path parameter because it is not
    // supported on web.
    await file.saveTo('');
    return null;
  }
}
