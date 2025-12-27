import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

class FormulaRiveViewer extends StatefulWidget {
  final String src;

  const FormulaRiveViewer({super.key, required this.src});

  @override
  State<FormulaRiveViewer> createState() => _FormulaRiveViewerState();
}

class _FormulaRiveViewerState extends State<FormulaRiveViewer> {
  late final rive.FileLoader _fileLoader;
  rive.RiveWidgetController? _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the loader with the asset path passed from the parent
    _fileLoader = rive.FileLoader.fromAsset(
      widget.src,
      riveFactory: rive.Factory.rive,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 1. Claim gestures to prevent parent scrolling while interacting
      onVerticalDragUpdate: (_) {},
      onHorizontalDragUpdate: (_) {},
      // Optional: You might need these too depending on the specific interaction
      //onPanUpdate: (_) {},

      child: rive.RiveWidgetBuilder(
        fileLoader: _fileLoader,
        builder: (context, state) {
          return switch (state) {
            rive.RiveLoading() => const Center(
                child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 2)
                )
            ),
            rive.RiveFailed() => const Center(
                child: Text(
                  'Error loading animation',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                )
            ),
            rive.RiveLoaded() => _buildRive(state),
          };
        },
      ),
    );
  }

  Widget _buildRive(rive.RiveLoaded state) {
    // Create controller once.
    // Note: We assume default Artboard/StateMachine names here.
    // If your files have specific names, you might need to pass them or use default Artboard.
    _controller ??= rive.RiveWidgetController(
      state.file,
      // If you don't know the artboard name, removing artboardSelector
      // usually defaults to the first artboard.
      stateMachineSelector: rive.StateMachineSelector.byName('State Machine 1'),
    );
    _controller!.dataBind(rive.DataBind.auto());
    return rive.RiveWidget(controller: _controller!);
  }
}