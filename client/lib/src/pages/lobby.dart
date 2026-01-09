import "dart:io";

import "package:flutter/material.dart";
import "package:mdeal/view_models.dart";
import "package:mdeal/widgets.dart";
import "package:shared/utils.dart";

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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: model.nameController,
                  decoration: const InputDecoration(
                    label: Text("Username"),
                  ),
                ),
              ),
              DropdownButton<InternetAddress>(
                items: [
                  for (final item in LobbyViewModel.addresses)
                    DropdownMenuItem(
                      value: item,
                      child: Text(item.address),
                    ),
                ],
                value: model.address,
                onChanged: (item) => model.updateAddress(item),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (model.hasJoined)
            Text(model.isReady ? "Ready" : "Not Ready"),
          const Divider(),
          for (final (user, isReady) in model.users.records)
            ListTile(
              title: Text(user),
              trailing: isReady
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.pending),
            ),
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
