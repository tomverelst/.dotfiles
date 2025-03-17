function save
    set -l path /Users/tom/git/obsidian
    if string length -q (git -C $path status --porcelain)
      git -C $path add -A > /dev/null
      git -C $path commit -m "chore: save work" > /dev/null
      git -C $path push --signed=true > /dev/null
      echo "✅ Work saved!":
    else
      echo "✅ No work to save."
    end
end
