class StringUtils {
  static String normalize(String input) {
    var text = input.trim().toLowerCase();
    
    var withDia = 'àáâãäåòóôõöøèéêëìíîïùúûüÿñç';
    var withoutDia = 'aaaaaaooooooeeeeiiiiuuuuync';
    
    for (int i = 0; i < withDia.length; i++) {
      text = text.replaceAll(withDia[i], withoutDia[i]);
    }
    
    // Remove extra spaces or special characters if needed
    // text = text.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    
    return text;
  }
}
