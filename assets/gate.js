(function() {
  if (sessionStorage.getItem('maha-auth') === '1') {
    document.getElementById('pw-gate').style.display = 'none';
  }
})();
function checkPw() {
  const val = document.getElementById('pw-input').value;
  // simple hash check — change the hash when you go live (or just remove the gate)
  if (val === atob('dHJhY2t0aGlzMjAyNg==')) {
    sessionStorage.setItem('maha-auth', '1');
    document.getElementById('pw-gate').style.display = 'none';
  } else {
    document.getElementById('pw-error').classList.add('show');
    document.getElementById('pw-input').value = '';
  }
}
document.addEventListener('keydown', function(e) {
  if (e.key === 'Enter') checkPw();
});
