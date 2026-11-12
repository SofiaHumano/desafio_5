import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../domain/entities/post.dart';
import '../providers/posts_provider.dart';
import 'detalle_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();

  late Future<List<Post>> _postsFuture;

  bool _buscando = false;
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _postsFuture = _cargarPosts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Post>> _cargarPosts({bool forzar = false}) async {
    final guardados = ref.read(postsProvider);
    if (guardados.isNotEmpty && !forzar) return guardados;

    final posts = await _apiService.getPosts();
    if (mounted) {
      ref.read(postsProvider.notifier).guardar(posts);
    }
    return posts;
  }

  void _alternarBusqueda() {
    setState(() {
      if (_buscando) {
        _buscando = false;
        _consulta = '';
        _controller.clear();
      } else {
        _buscando = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        title: _buscando
            ? TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar por título...',
            border: InputBorder.none,
          ),
          onChanged: (valor) {
            setState(() {
              _consulta = valor;
            });
          },
        )
            : const Text('Noticias'),
        actions: [
          IconButton(
            icon: Icon(_buscando ? Icons.close : Icons.search),
            onPressed: _alternarBusqueda,
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando noticias...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 64),
                    const SizedBox(height: 16),
                    const Text('Error al cargar los datos'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _postsFuture = _cargarPosts(forzar: true);
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<Post> todos = snapshot.data!;
          final texto = _consulta.trim().toLowerCase();
          final List<Post> posts = todos
              .where((p) => p.title.toLowerCase().contains(texto))
              .toList();

          if (posts.isEmpty) {
            return const Center(child: Text('No hay noticias con ese título'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    '${post.id}',
                    style: TextStyle(color: cs.onPrimaryContainer),
                  ),
                ),
                title: Text(post.title),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleScreen(post: post),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}