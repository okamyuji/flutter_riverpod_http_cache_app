import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/posts_provider.dart';
import 'constants/strings.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: Text(Strings.appBarTitle),
        ),
        body: const PostsList(),
      ),
    );
  }
}

class PostsList extends ConsumerWidget {
  const PostsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(postsProvider);

    return postsAsyncValue.when(
      data: (posts) {
        return RefreshIndicator(
          onRefresh: () {
            final future = ref.refresh(postsProvider.future);
            future.then((_) {
              if (!context.mounted) return;
              if (ref.read(postsProvider).hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Strings.refreshErrorMessage),
                  ),
                );
              }
            });
            return future;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                title: Text(post['title']),
                subtitle: Text(post['body']),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('${Strings.genericErrorPrefix}$err'),
      ),
    );
  }
}
