class FileAccess                                      #ファイル関係のクラス
  def initialize
    @sum_island = 0
    @adjacent_island = 0
  end

  def file_read                                       #マップを開いて格納する関数
    file_map = open("map.txt")                       
    @sum_island = file_map.gets.to_i                  #1行目（島の総数）を整数型として格納
    @adjacent_island = file_map.readlines             #ファイルを全て読み、行ごとに格納
    file_map.close                                    
  end

  def file_write(history)                                  #スタンプシートに書き込む関数
    file_stampsheet = open("stampsheet.txt","w")           #ファイルのオープン（書き込み）
    history.map! do |item|                                 #行った島のスタンプを押す
      file_stampsheet.puts "#{item}"
    end
    file_stampsheet.close                                  #ファイルのクローズ
  end

  attr_accessor :sum_island, :adjacent_island
end


class ChooseIsland                                               #島を選ぶクラス
  def initialize(sum_island)   
    @start_island_number = 0
    @number_of_adjacent_island_start = 0
    @next_island_number = nil
    @number_of_adjacent_island_next = sum_island
  end

  def start_island(sum_island, adjacent_island)                  #最初の島を選ぶ関数
    @start_island_number = 0
    @number_of_adjacent_island_start = 0
    sum_island.times do |i|                                             #全ての島に適用
      if @number_of_adjacent_island_start < adjacent_island[i].size     #隣接数が一番多い島を選ぶ
        @number_of_adjacent_island_start = adjacent_island[i].size      #隣接数の記憶
        @start_island_number = i                                        #島番号の記憶
      end
    end
    return @start_island_number                                         #島番号を返す
  end

  def next_island(sum_island, adjacent_island, current_island)          #次の島を決める関数
    @next_island_number = nil
    @number_of_adjacent_island_next = sum_island
    adjacent_island[current_island].map do |item|                       #隣接島の要素全てに適用

      #隣接数が0でなく、一番少ない島を選ぶ
      if @number_of_adjacent_island_next > adjacent_island[item].size && adjacent_island[item].size != 0
        @number_of_adjacent_island_next = adjacent_island[item].size                                        #隣接数の記憶
        @next_island_number = item                                                                          #島番号の記憶
      end
    end

    if @next_island_number == nil
      return adjacent_island[current_island][0]
    end
    return @next_island_number
  end
end


class Preparation                                      #探索の準備をするクラス（1文字ずつにわける、型の変換、枝切り）
  def initialize
    @delete = []                                       #消す島を記憶するための配列deleteを宣言
    @delete_tmp = []                                   #一時的にdeleteの代わりになる配列  deleteの中身を変えたくない時に使用
  end

  def transform(sum_island, adjacent_island)                   #文字型から整数型に変換する関数
    sum_island.times do |i|                                    #全ての島に適用
      adjacent_island[i] = adjacent_island[i].split(" ")       #1文字ずつに分ける
      adjacent_island[i].map! do |item|                        #隣接島の要素全てに適用
        item.to_i                                              #文字型を整数型にする
      end

      if adjacent_island[i].size == 1                          #隣接数が1なら
        adjacent_island[i].clear                               #その島を選択肢から外す→行き止まりに達する可能性を減らすため
        @delete << i                                           #消す島の記憶
      end
    end
  end

  def pruning(sum_island, adjacent_island)                      #枝切りの関数　枝切り：隣接数1の島を消して行き止まりに達する可能性を減らす
    while @delete != []                                         #隣接数が1の島が無くなるまで繰り返す
      sum_island.times{ |i|                                     #全ての島に適用
      adjacent_island[i] = adjacent_island[i] - @delete         #隣接島から消す島(隣接数が1の島)を消す
        if adjacent_island[i].size == 1                         #これによって新たに隣接数1の島が生じた場合
          adjacent_island[i].clear                              #その島を選択肢から外す
          @delete_tmp << i                                      #消す島の記憶  ループ中のためdeleteの中身をいじるわけにはいかないので一時的にdelete_tmpに記憶
        end
      }
      @delete = @delete_tmp                                     #delete_tmpの中身をdeleteに移す
      @delete_tmp.clear                                         #delete_tmpの初期化
    end
  end
end


class SearchSupport                                                    #島の探索を支援するクラス（削除、判定など）
  def delete_island(sum_island, adjacent_island, current_island)       #通った島を選択肢から削除する関数
    sum_island.times do |i|                                            #全ての島に適用
      adjacent_island[i].delete(current_island)                        #通った島を配列から消す  差集合をとるより処理が速い？差集合では配列の要素が大きくなりすぎるから？
    end
  end
    
  def check_possible_search(adjacent_island, current_island)           #次の島に行けるかどうか判定する関数                  
    return adjacent_island[current_island] == []
  end
end


history = []                        #通った島を記憶する配列

#クラスの宣言
file_access = FileAccess.new()
choose_island = ChooseIsland.new(file_access.sum_island)
preparation = Preparation.new()
search_support = SearchSupport.new()

start_time = Time.now               #開始時刻の取得
file_access.file_read()             #mapを読み込む       
preparation.transform(file_access.sum_island, file_access.adjacent_island)     #1文字ずつに分ける&枝切り準備
preparation.pruning(file_access.sum_island, file_access.adjacent_island)       #枝切り


#島を移動する処理
current_island = choose_island.start_island(file_access.sum_island, file_access.adjacent_island)       #最初の島を決定
while true
  history << current_island                                                                            #通った島の記憶

  search_support.delete_island(file_access.sum_island, file_access.adjacent_island, current_island)    #通った島を削除

  break if search_support.check_possible_search(file_access.adjacent_island, current_island)           #隣接する島がなくなったらループを抜ける

  current_island = choose_island.next_island(file_access.sum_island, file_access.adjacent_island, current_island)         #次の島を決定
end

file_access.file_write(history)
end_time = Time.now
time = end_time - start_time
score = history.size**3/file_access.sum_island*time        #scoreの計算
puts "score is #{score}"                                   #scoreの表示
puts "time is #{time}"
puts "number of island is #{history.size}"
