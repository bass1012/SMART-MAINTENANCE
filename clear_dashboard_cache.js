// Copiez-collez ce code dans la console du navigateur (F12)
// Puis appuyez sur Entrée

Object.keys(localStorage).forEach(key => {
  if (key.startsWith('chat_messages_')) {
    localStorage.removeItem(key);
    console.log('🗑️ Cache supprimé:', key);
  }
});

console.log('✅ Tous les caches de chat supprimés du dashboard');
console.log('🔄 Rechargez la page (Cmd+R)');
