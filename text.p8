message_timer = 0
message_duration = 3 * 30  -- 3 seconds, assuming 30 FPS

-- Function to check if a number is prime
function is_prime(num)
    if num <= 1 then return false end
    if num <= 3 then return true end
    if num % 2 == 0 or num % 3 == 0 then return false end

    local i = 5
    while i * i <= num do
        if num % i == 0 or num % (i + 2) == 0 then
            return false
        end
        i = i + 6
    end
    return true
end

-- Function to generate the first 46 prime numbers
function generate_primes()
    local primes = {}
    local count = 0
    local i = 2

    while count < 46 do
        if is_prime(i) then
            add(primes, i)
            count = count + 1
        end
        i = i + 1
    end

    return primes
end

-- The strings to be indexed by prime numbers
local messages = {
    "What could be bigger in scale than something that is endless?",
    "Is anything ever endless?",
    "Would you call the Universe endless?",
    "Why care?",
    "Just relax, it's golf",
    "and it's Possibly Endless Golf",
    "carry on",
    "and chill",
    "rewind or restart",
    "skip it if you want to",
    "just enjoy the journey",
    "for what else do we have?",
    "you're outdoors, maybe even indoors?",
    "You're on a mountain, in a desert",
    "On another Planet!",
    "Messages in prime number order?",
    "but one is not a prime",
    "Zero was invented",
    "and didn't always exist",
    "there are 168 prime numbers between 1 & 1000",
    "Egyptian Rhind Papyrus",
    "The Sand Reckoner",
    "or Anaximander's apeiron?",
    "Who discovered infinity first?",
    "Can infinity be discovered?",
    "Would you want to be infinite?",
    "What is infinity minus one?",
    "If infinity is just a concept",
    "then is life just a concept",
    "Is bordem having nothing to do",
    "or doing too much of the same thing?",
    "Do fish get bored?",
    "How do dreams seem endless",
    "when you've only pressed snooze once"
}
-- Generate the prime numbers
local prime_indices = generate_primes()

-- Create a table with prime indices
prime_indexed_strings = {}
for i, prime in ipairs(prime_indices) do
    printh('prime: ' .. prime)
    prime_indexed_strings[prime] = messages[i]
end

function show_message(msg)
    message = msg
    --message_timer = message_duration
end

-- Function to print each line centered
function print_centered(text, y, color)
    local lines = split(text, "\n")
    for i, line in ipairs(lines) do
        local x = (128 - #line * 4) / 2 -- Centering calculation
        print(line, x, y + (i - 1) * 6, color) -- 6 pixels between lines
    end
end

-- Function to automatically insert newlines at spaces in a long string
function auto_newline(text, max_width)
    local result = ""
    local line = ""
    local last_space_index = 0
    local i = 1

    while i <= #text do
        local char = sub(text, i, i)
        line = line .. char

        if char == ' ' then
            last_space_index = i
        end

        -- Check if line reached max width
        if #line * 4 >= max_width then
            if last_space_index ~= 0 then
                -- Break line at the last space
                result = result .. sub(text, 1, last_space_index) .. "\n"
                -- Reset text starting after the last space
                text = sub(text, last_space_index + 1)
                line = ""
                i = 1  -- Reset index to start of new text portion
                last_space_index = 0
            else
                -- Break line at current position if no space found
                result = result .. line .. "\n"
                text = sub(text, i + 1)
                line = ""
                i = 1  -- Reset index to start of new text portion
            end
        else
            i = i + 1  -- Increment index if max width not reached
        end
    end

    -- Add the last line
    result = result .. line
    return result
end