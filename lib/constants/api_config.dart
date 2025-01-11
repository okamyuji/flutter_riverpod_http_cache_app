class ApiConfig {
  static const baseUrl = 'https://jsonplaceholder.typicode.com';
  static const postsEndpoint = '/posts';

  static String get postsUrl => baseUrl + postsEndpoint;
}
