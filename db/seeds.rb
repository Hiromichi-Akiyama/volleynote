# 管理者ユーザーの作成
admin_user = User.find_or_create_by(email: 'admin@volleynote.com') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
  u.team_name = 'サンプルバレーボールチーム'
  u.coach_name = '監督 太郎'
end

# デモユーザーの作成
demo_user = User.find_or_create_by(email: 'demo@volleynote.com') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
  u.team_name = 'デモチーム'
  u.coach_name = 'デモ監督'
end

# 選手データの作成
players_data = [
  {
    name: "田中 太郎", number: 1, position: "セッター",
    spike_attempts: 25, spike_kills: 15, recv_attempts: 40, recv_successes: 32,
    serve_attempts: 20, serve_effects: 8, serve_points: 3
  },
  {
    name: "佐藤 健一", number: 5, position: "ウイングスパイカー",
    spike_attempts: 45, spike_kills: 28, recv_attempts: 35, recv_successes: 25,
    serve_attempts: 18, serve_effects: 12, serve_points: 5
  },
  {
    name: "山田 次郎", number: 10, position: "ミドルブロッカー",
    spike_attempts: 30, spike_kills: 22, recv_attempts: 15, recv_successes: 10,
    serve_attempts: 15, serve_effects: 6, serve_points: 2
  },
  {
    name: "鈴木 雄介", number: 3, position: "リベロ",
    spike_attempts: 8, spike_kills: 3, recv_attempts: 65, recv_successes: 58,
    serve_attempts: 12, serve_effects: 4, serve_points: 1
  },
  {
    name: "高橋 健太", number: 7, position: "オポジット",
    spike_attempts: 38, spike_kills: 26, recv_attempts: 22, recv_successes: 16,
    serve_attempts: 25, serve_effects: 15, serve_points: 8
  },
  {
    name: "伊藤 翔太", number: 9, position: "ウイングスパイカー",
    spike_attempts: 42, spike_kills: 24, recv_attempts: 28, recv_successes: 20,
    serve_attempts: 22, serve_effects: 9, serve_points: 4
  },
  {
    name: "中村 大輔", number: 2, position: "セッター",
    spike_attempts: 18, spike_kills: 10, recv_attempts: 32, recv_successes: 26,
    serve_attempts: 28, serve_effects: 11, serve_points: 6
  },
  {
    name: "松本 祐樹", number: 4, position: "ミドルブロッカー",
    spike_attempts: 35, spike_kills: 21, recv_attempts: 12, recv_successes: 8,
    serve_attempts: 16, serve_effects: 7, serve_points: 3
  },
  {
    name: "渡辺 拓也", number: 6, position: "ウイングスパイカー",
    spike_attempts: 40, spike_kills: 23, recv_attempts: 30, recv_successes: 22,
    serve_attempts: 20, serve_effects: 8, serve_points: 2
  },
  {
    name: "小林 正樹", number: 8, position: "リベロ",
    spike_attempts: 5, spike_kills: 2, recv_attempts: 58, recv_successes: 52,
    serve_attempts: 14, serve_effects: 5, serve_points: 1
  }
]

# 各ユーザーに選手データを作成
[admin_user, demo_user].each do |user|
  players_data.each do |player_data|
    user.players.find_or_create_by(number: player_data[:number]) do |player|
      player.assign_attributes(player_data)
    end
  end
end

puts "#{User.count} users created."
puts "#{Player.count} players created."