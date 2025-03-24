function save
    set -l path /Users/tom/git/obsidian
    if string length -q (git -C $path status --porcelain)
      git -C $path add -A > /dev/null
      git -C $path commit -m "chore: save work" > /dev/null
      if git -C $path push > /dev/null
        echo "✅ Work saved!"
      end
    else
      echo "✅ No work to save."
    end
end
