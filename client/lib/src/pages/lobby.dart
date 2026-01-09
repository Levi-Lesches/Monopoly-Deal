import "package:flutter/material.dart";
import "package:mdeal/view_models.dart";
import "package:mdeal/widgets.dart";

class LobbyPage extends ReactiveWidget<LobbyViewModel> {
  @override
  LobbyViewModel createModel() => LobbyViewModel();

  @override
  Widget build(BuildContext context, LobbyViewModel model) => Scaffold(
    appBar: AppBar(title: const Text("Lobby"),),
    body: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            controller: model.nameController,
            decoration: const InputDecoration(
              label: Text("Username"),
            ),
          ),
          const SizedBox(height: 12),
          if (model.hasJoined)
            Text(model.isReady ? "Ready" : "Not Ready"),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: model.canJoin && !model.isLoading ? model.joinLobby : null,
                child: const Text("Join"),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: model.canReady && !model.isLoading ? model.toggleReady : null,
                child: const Text("Ready"),
              ),
            ],
          )
        ],
      ),
    ),
  );
}
