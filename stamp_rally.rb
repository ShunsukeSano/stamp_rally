class FileManager                                      #ファイル関係のクラス
  def file_read                                        #マップを開いて格納する関数
    file_map = open("map.txt")                       
    sum_island = file_map.gets.to_i                    #1行目（島の総数）を整数型として格納
    adjacent_island = file_map.readlines               #ファイルを全て読み、行ごとに格納
    file_map.close
    return sum_island, adjacent_island                                  
  end

  def file_write(history)                                  #スタンプシートに書き込む関数
    file_stampsheet = open("stampsheet.txt","w")           #ファイルのオープン（書き込み）
    history.map! do |item|                                 #行った島のスタンプを押す
      file_stampsheet.puts "#{item}"
    end
    file_stampsheet.close                                  #ファイルのクローズ
  end
end


class Searcher                                             #探索するクラス
  def initialize(sum_island, adjacent_island)
    @sum_island = sum_island
    @adjacent_island = adjacent_island
  end

  def stamp_rally
    history = []                                           #通った島を記憶する配列
    current_island = start_island
    loop do
      history << current_island                            #通った島の記憶
      delete_island(current_island)
  
      break if @adjacent_island[current_island].empty?     #隣接する島がなくなったらループを抜ける

      current_island = next_island(current_island)         #次の島を決定
    end
    return history
  end

  def start_island                                                     #最初の島を選ぶ関数
    start_island_number = 0
    number_of_adjacent_island = 0
    @adjacent_island.each_with_index do |data, i|                      #全ての島に適用
      if number_of_adjacent_island < data.size                         #隣接数が一番多い島を選ぶ
        number_of_adjacent_island = data.size                          #隣接数の記憶
        start_island_number = i                                        #島番号の記憶
      end
    end
    return start_island_number                                         #島番号を返す
  end

  def delete_island(current_island)
    @adjacent_island.each do |data|                                    #全ての島に適用
      data.delete(current_island)                                      #通った島を配列から消す  差集合をとるより処理が速い？差集合では配列の要素が大きくなりすぎるから？
    end
  end

  def next_island(current_island)                                      #次の島を決める関数
    next_island_number = nil
    number_of_adjacent_island = @sum_island
    @adjacent_island[current_island].map do |item|                     #隣接島の要素全てに適用

      #隣接数が0でなく、一番少ない島を選ぶ
      if number_of_adjacent_island > @adjacent_island[item].size && @adjacent_island[item].size != 0
        number_of_adjacent_island = @adjacent_island[item].size                                            #隣接数の記憶
        next_island_number = item                                                                          #島番号の記憶
      end
    end

    if next_island_number == nil
      return @adjacent_island[current_island][0]
    end
    return next_island_number
  end
end


class Preparator                                       #探索の準備をするクラス（1文字ずつにわける、型の変換、枝切り）
  def initialize(sum_island, adjacent_island) 
    @delete = []                                       #消す島を記憶するための配列deleteを宣言
    @sum_island = sum_island
    @adjacent_island = adjacent_island
  end

  def format                                                   #文字型から整数型に変換する関数
    @sum_island.times do |i|                                   #全ての島に適用
      @adjacent_island[i] = @adjacent_island[i].split(" ")     #1文字ずつに分ける
      @adjacent_island[i].map! do |item|                       #隣接島の要素全てに適用
        item.to_i                                              #文字型を整数型にする
      end

     delete_isolated_island(@adjacent_island[i], i, @delete)
    end
  end

  def pruning                                                      #枝切りの関数　枝切り：隣接数1の島を消して行き止まりに達する可能性を減らす
    delete_tmp =[]
    while @delete != []                                            #隣接数が1の島が無くなるまで繰り返す
      @adjacent_island.each_with_index do |data, i|                #全ての島に適用
        data = data - @delete                                      #隣接島から消す島(隣接数が1の島)を消す
        delete_isolated_island(data, i, delete_tmp)
      end
      @delete = delete_tmp                                         #delete_tmpの中身をdeleteに移す
      delete_tmp.clear                                             #delete_tmpの初期化
    end
    return @adjacent_island
  end

  def delete_isolated_island(adjacent_island, island_index, array)
    if adjacent_island.size == 1                                   #隣接数が1なら
        adjacent_island.clear                                      #その島を選択肢から外す→行き止まりに達する可能性を減らすため
        array << island_index                                      #消す島の記憶
      end
  end
end


file_manager = FileManager.new()
sum_island, adjacent_island = file_manager.file_read               #mapを読み込む

preparation = Preparator.new(sum_island, adjacent_island)
preparation.format                                                 #1文字ずつに分ける&枝切り準備
adjacent_island = preparation.pruning                              #枝切り

searcher = Searcher.new(sum_island, adjacent_island)
history = searcher.stamp_rally                                     #島を移動する処理

file_manager.file_write(history)